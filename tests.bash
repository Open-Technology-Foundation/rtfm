#!/usr/bin/env bash
# tests.bash - Comprehensive test suite for rtfm
#
# Usage: ./tests.bash [pattern]
#   pattern   Optional substring filter; only test names containing this
#             string are executed. Useful for narrowing during debugging.
#
# Exit: 0 if every executed test passed, 1 otherwise.
#
# What is tested:
#   - CLI option parsing (short, long, combined, --, errors)
#   - Input validation (whitelist, length, metachars, dash-prefix, traversal)
#   - Source lookups (builtin / man / info / tldr / --help fallback)
#   - Colour detection (NO_COLOR, FORCE_COLOR, CLICOLOR_FORCE, TTY redirect)
#   - Exit-code contract (0 / 2 / 22)
#   - Edge cases (no args, too-many args, missing index file)
#   - update-checksums.sh (regeneration, missing-file rejection)
#
# What is NOT tested (would mutate system state or require network/sudo):
#   - --install / --update (clones repos, writes /usr/local, requires sudo)
#   - --rebuild-lists (requires sudo, rewrites /usr/local/share/rtfm/*.list)
#   - True TTY behaviour for colour defaults (would need a pty)

# Test bodies are dispatched indirectly through run_test() via $fn, so the
# linter cannot trace their callers. SC2329 is silenced file-wide below
# rather than annotating each helper / test function individually.
# shellcheck disable=SC2329

set -euo pipefail
shopt -s inherit_errexit

# --- Metadata ---

declare -- SCRIPT_DIR
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly SCRIPT_DIR
declare -r RTFM="$SCRIPT_DIR/rtfm"
declare -r UPDATE_CHECKSUMS="$SCRIPT_DIR/update-checksums.sh"

# Optional substring filter; if empty, all tests run.
declare -r FILTER=${1:-}

# Colours: enabled only when stderr is a TTY.
if [[ -t 2 ]]; then
  declare -r RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' CYAN=$'\033[0;36m' NC=$'\033[0m'
else
  declare -r RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

# --- Test-runner state ---

declare -i TESTS_RUN=0 TESTS_PASS=0 TESTS_FAIL=0 TESTS_SKIP=0
declare -a FAILURES=()

# Per-test captures, refreshed by cap().
declare -i LAST_EXIT=0
declare -- LAST_OUT='' LAST_ERR=''

# --- Helpers ---

# Print to stderr; preserves stdout for any test that pipes us.
say() { >&2 printf '%s\n' "$*"; }

# Run a command with cleared rtfm env vars, capture stdout / stderr / exit
# without aborting under set -e. Sets LAST_OUT, LAST_ERR, LAST_EXIT.
# Args: command and its args.
cap() {
  local -- errfile
  errfile=$(mktemp)
  LAST_EXIT=0
  # NOTE: subshell to scope env scrubs and avoid -e tripping on test failures.
  LAST_OUT=$(
    unset NO_COLOR FORCE_COLOR CLICOLOR_FORCE
    "$@" 2>"$errfile"
  ) || LAST_EXIT=$?
  LAST_ERR=$(<"$errfile")
  rm -f "$errfile"
}

# Same as cap() but caller controls the environment (used by colour tests).
cap_raw() {
  local -- errfile
  errfile=$(mktemp)
  LAST_EXIT=0
  LAST_OUT=$("$@" 2>"$errfile") || LAST_EXIT=$?
  LAST_ERR=$(<"$errfile")
  rm -f "$errfile"
}

# Record pass / fail outcome.
pass() {
  ((++TESTS_RUN, ++TESTS_PASS))
  say "  ${GREEN}✓${NC} $1"
}

fail() {
  ((++TESTS_RUN, ++TESTS_FAIL))
  FAILURES+=("$1 — $2")
  say "  ${RED}✗${NC} $1"
  say "      ${YELLOW}reason:${NC} $2"
  [[ -z $LAST_OUT ]] || say "      ${CYAN}stdout:${NC} $(head -c 200 <<<"$LAST_OUT")"
  [[ -z $LAST_ERR ]] || say "      ${CYAN}stderr:${NC} $(head -c 200 <<<"$LAST_ERR")"
}

skip() {
  ((++TESTS_RUN, ++TESTS_SKIP))
  say "  ${YELLOW}~${NC} $1 (skipped: $2)"
}

# Should this test run, given the optional FILTER?
matches_filter() {
  [[ -z $FILTER ]] || [[ $1 == *"$FILTER"* ]]
}

# --- Assertion primitives (read LAST_* set by cap/cap_raw) ---

assert_exit() {
  local -i want=$1
  local -- name=$2
  if ((LAST_EXIT == want)); then
    pass "$name"
  else
    fail "$name" "exit=$LAST_EXIT want=$want"
  fi
}

assert_stdout_contains() {
  local -- needle=$1 name=$2
  if [[ $LAST_OUT == *"$needle"* ]]; then
    pass "$name"
  else
    fail "$name" "stdout missing substring ${needle@Q}"
  fi
}

assert_stderr_contains() {
  local -- needle=$1 name=$2
  if [[ $LAST_ERR == *"$needle"* ]]; then
    pass "$name"
  else
    fail "$name" "stderr missing substring ${needle@Q}"
  fi
}

assert_stdout_no_ansi() {
  local -- name=$1
  if [[ $LAST_OUT != *$'\033'* ]]; then
    pass "$name"
  else
    fail "$name" 'stdout contains ANSI escape (expected none)'
  fi
}

assert_stdout_has_ansi() {
  local -- name=$1
  if [[ $LAST_OUT == *$'\033'* ]]; then
    pass "$name"
  else
    fail "$name" 'stdout missing ANSI escape (expected colour)'
  fi
}

# --- Section header ---

section() {
  say ''
  say "${CYAN}▼ $1${NC}"
}

# --- Test wrapper ---
# Each test() call gates on the filter and increments counts via the
# downstream assert_* helpers. The body is a function name to call.
run_test() {
  local -- name=$1 fn=$2
  if ! matches_filter "$name"; then return 0; fi
  $fn "$name"
}

# ====================================================================
# TESTS
# ====================================================================

# --- 1. Smoke / metadata --------------------------------------------------

t_version() {
  cap "$RTFM" --version
  assert_exit 0 "$1 [exit]"
  assert_stdout_contains 'rtfm ' "$1 [output]"
}

t_version_short() {
  cap "$RTFM" -V
  assert_exit 0 "$1 [exit]"
  assert_stdout_contains 'rtfm ' "$1 [output]"
}

t_help_long() {
  cap "$RTFM" --help
  assert_exit 0 "$1 [exit]"
  assert_stdout_contains 'USAGE' "$1 [USAGE block]"
  assert_stdout_contains 'OPTIONS' "$1 [OPTIONS block]"
  assert_stdout_contains 'ENVIRONMENT' "$1 [ENVIRONMENT block]"
}

t_help_short() {
  cap "$RTFM" -h
  assert_exit 0 "$1 [exit]"
  assert_stdout_contains 'Read The Fucking Manuals' "$1 [title]"
}

t_no_args_shows_help() {
  cap "$RTFM"
  assert_exit 2 "$1 [exit=2]"
  assert_stderr_contains 'USAGE' "$1 [help on stderr]"
}

# --- 2. Option parsing ----------------------------------------------------

t_bad_long_option() {
  cap "$RTFM" --bogus
  assert_exit 22 "$1 [exit=22]"
  assert_stderr_contains 'Invalid option' "$1 [message]"
}

t_bad_short_option() {
  cap "$RTFM" -Z
  assert_exit 22 "$1 [exit=22]"
  assert_stderr_contains 'Invalid option' "$1 [message]"
}

t_too_many_args() {
  cap "$RTFM" one two
  assert_exit 2 "$1 [exit=2]"
  assert_stderr_contains 'Too many arguments' "$1 [message]"
}

t_double_dash_terminates_options() {
  # After --, a command name beginning with '-' is captured as the
  # command (and rejected by validate_command_name, not the option parser).
  cap "$RTFM" -- -rm
  assert_exit 22 "$1 [exit=22]"
  assert_stderr_contains 'cannot start with a dash' "$1 [validation message]"
}

t_double_dash_with_valid_command() {
  cap "$RTFM" -- ls
  # ls is in man.list on virtually all Linux installs; exit 0 expected.
  assert_exit 0 "$1 [exit=0 for ls after --]"
}

t_combined_short_flags_vq() {
  # -vq must expand to -v -q; declare is a builtin so resolution succeeds.
  cap "$RTFM" -vq declare
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_contains 'declare' "$1 [output mentions declare]"
}

t_combined_short_flags_qV() {
  # Combined flags including a terminator (-V).
  cap "$RTFM" -qV
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_contains 'rtfm ' "$1 [version printed]"
}

# --- 3. Input validation --------------------------------------------------

t_validation_empty_via_dash_dash() {
  # Empty positional via -- with nothing after: parser falls through, no cmd.
  cap "$RTFM" --
  assert_exit 2 "$1 [exit=2 no command]"
  assert_stderr_contains 'No command specified' "$1 [message]"
}

t_validation_metachar_semicolon() {
  cap "$RTFM" 'foo;bar'
  assert_exit 22 "$1 [exit=22]"
  assert_stderr_contains 'Invalid command name' "$1 [message]"
}

t_validation_metachar_dollar() {
  # shellcheck disable=SC2016  # the literal $ is the point of the test
  cap "$RTFM" -- 'a$b'
  assert_exit 22 "$1 [exit=22]"
}

t_validation_metachar_backtick() {
  cap "$RTFM" -- 'a`b'
  assert_exit 22 "$1 [exit=22]"
}

t_validation_metachar_pipe() {
  cap "$RTFM" -- 'a|b'
  assert_exit 22 "$1 [exit=22]"
}

t_validation_metachar_redirect() {
  cap "$RTFM" -- 'a>b'
  assert_exit 22 "$1 [exit=22]"
}

t_validation_metachar_glob() {
  cap "$RTFM" -- 'a*b'
  assert_exit 22 "$1 [exit=22]"
}

t_validation_traversal() {
  cap "$RTFM" -- '../etc/passwd'
  assert_exit 22 "$1 [exit=22]"
}

t_validation_slash() {
  cap "$RTFM" -- 'bin/ls'
  assert_exit 22 "$1 [exit=22]"
}

t_validation_dash_prefix() {
  cap "$RTFM" -- '-rm'
  assert_exit 22 "$1 [exit=22]"
  assert_stderr_contains 'cannot start with a dash' "$1 [message]"
}

t_validation_too_long() {
  # 65 chars: one over the 64-char limit.
  local -- long_name
  long_name=$(printf 'a%.0s' {1..65})
  cap "$RTFM" -- "$long_name"
  assert_exit 22 "$1 [exit=22]"
  assert_stderr_contains 'too long' "$1 [message]"
}

t_validation_accepts_valid_chars() {
  # alnum, dot, dash, underscore, plus — all allowed.
  cap "$RTFM" -- 'python3.12'
  # Resolution may exit 0 (found) or 0 with "No help found"; both fine.
  assert_exit 0 "$1 [valid chars accepted, exit=0]"
}

t_validation_accepts_plus() {
  cap "$RTFM" -- 'g++'
  assert_exit 0 "$1 [plus accepted]"
}

# --- 4. Source lookups ----------------------------------------------------

t_lookup_builtin() {
  cap "$RTFM" declare
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_contains 'BUILTIN' "$1 [BUILTIN section]"
  assert_stdout_contains 'declare' "$1 [content]"
}

t_lookup_man() {
  if [[ ! -f /usr/local/share/rtfm/man.list ]]; then
    skip "$1" 'man.list not installed'
    return 0
  fi
  cap "$RTFM" ls
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_contains 'MAN' "$1 [MAN section]"
}

t_lookup_info() {
  if ! grep -q '^coreutils$' /usr/local/share/rtfm/info.list 2>/dev/null; then
    skip "$1" 'coreutils info page not indexed'
    return 0
  fi
  cap "$RTFM" coreutils
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_contains 'INFO' "$1 [INFO section]"
}

t_lookup_tldr() {
  if ! grep -q '^rsync$' /usr/local/share/rtfm/tldr.list 2>/dev/null; then
    skip "$1" 'rsync tldr page not indexed'
    return 0
  fi
  cap "$RTFM" rsync
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_contains 'TLDR' "$1 [TLDR section]"
}

t_lookup_multi_source_concat() {
  # find is documented in multiple sources on most systems.
  if [[ ! -f /usr/local/share/rtfm/man.list ]]; then
    skip "$1" 'man.list not installed'
    return 0
  fi
  cap "$RTFM" find
  assert_exit 0 "$1 [exit=0]"
  # Expect either MAN or INFO (find is GNU coreutils-adjacent).
  if [[ $LAST_OUT == *MAN* ]] || [[ $LAST_OUT == *INFO* ]]; then
    pass "$1 [contains MAN or INFO]"
  else
    fail "$1 [contains MAN or INFO]" 'neither MAN nor INFO present in output'
  fi
}

t_lookup_unknown_command() {
  cap "$RTFM" zzznosuchcommand12345
  assert_exit 0 "$1 [exit=0 even on miss]"
  assert_stdout_contains 'No help found' "$1 [fallback message]"
}

t_lookup_help_fallback() {
  # rtfm itself is a text script with --help, so the fallback path fires
  # ONLY when no other source matches. Since 'rtfm' is unlikely to be in
  # builtin/man/info/tldr lists, the fallback should trigger.
  if grep -q '^rtfm$' /usr/local/share/rtfm/{builtin,man,info,tldr}.list 2>/dev/null; then
    skip "$1" 'rtfm itself indexed in a source list, fallback path masked'
    return 0
  fi
  cap "$RTFM" rtfm
  assert_exit 0 "$1 [exit=0]"
  # Either COMMAND HELP section appears, or "No help found" if rtfm not in PATH.
  if [[ $LAST_OUT == *'COMMAND HELP'* ]] || [[ $LAST_OUT == *'No help found'* ]]; then
    pass "$1 [fallback or graceful miss]"
  else
    fail "$1 [fallback or graceful miss]" "unexpected output"
  fi
}

# --- 5. Colour detection --------------------------------------------------

t_colour_no_color_strips_ansi() {
  cap_raw env -u FORCE_COLOR -u CLICOLOR_FORCE NO_COLOR=1 "$RTFM" --help
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_no_ansi "$1 [no ANSI in output]"
}

t_colour_force_color_emits_ansi() {
  if [[ ! -f /usr/local/share/rtfm/man.list ]] \
      || ! grep -q '^ls$' /usr/local/share/rtfm/man.list; then
    skip "$1" 'ls man page not indexed'
    return 0
  fi
  cap_raw env -u NO_COLOR FORCE_COLOR=1 "$RTFM" ls
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_has_ansi "$1 [ANSI present]"
}

t_colour_clicolor_force_emits_ansi() {
  if [[ ! -f /usr/local/share/rtfm/man.list ]] \
      || ! grep -q '^ls$' /usr/local/share/rtfm/man.list; then
    skip "$1" 'ls man page not indexed'
    return 0
  fi
  cap_raw env -u NO_COLOR -u FORCE_COLOR CLICOLOR_FORCE=1 "$RTFM" ls
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_has_ansi "$1 [ANSI present]"
}

t_colour_redirect_strips_ansi() {
  # Default behaviour: stdout is not a TTY (we are capturing), so no ANSI.
  cap "$RTFM" --help
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_no_ansi "$1 [no ANSI on non-TTY stdout]"
}

t_colour_no_color_wins_over_force_color() {
  # NO_COLOR takes priority over FORCE_COLOR per rtfm:25-32.
  cap_raw env NO_COLOR=1 FORCE_COLOR=1 "$RTFM" --help
  assert_exit 0 "$1 [exit=0]"
  assert_stdout_no_ansi "$1 [NO_COLOR wins]"
}

# --- 6. Exit code contract (integration) ----------------------------------

t_exit_codes_summary() {
  # Re-run a few cases purely to assert exit codes per the documented contract:
  #   0  = success or graceful miss
  #   2  = missing/extra command argument
  #   22 = invalid option or invalid command name
  cap "$RTFM" --version;        assert_exit 0  "$1 [0: --version]"
  cap "$RTFM" zzznosuchcmd1234; assert_exit 0  "$1 [0: graceful miss]"
  cap "$RTFM";                  assert_exit 2  "$1 [2: no args]"
  cap "$RTFM" a b;              assert_exit 2  "$1 [2: too many args]"
  cap "$RTFM" --bogus;          assert_exit 22 "$1 [22: bad option]"
  cap "$RTFM" 'a;b';            assert_exit 22 "$1 [22: bad command]"
}

# --- 7. update-checksums.sh -----------------------------------------------

t_checksums_regenerates() {
  if [[ ! -x $UPDATE_CHECKSUMS ]]; then
    skip "$1" 'update-checksums.sh not present'
    return 0
  fi
  # Save the live file, run the updater, diff, restore.
  local -- backup
  backup=$(mktemp)
  cp "$SCRIPT_DIR/checksums.sha256" "$backup"
  cap_raw bash -c "cd '$SCRIPT_DIR' && '$UPDATE_CHECKSUMS'"
  local -i regen_exit=$LAST_EXIT
  local -- new_hash_for_rtfm
  new_hash_for_rtfm=$(grep -E '  rtfm$' "$SCRIPT_DIR/checksums.sha256" | awk '{print $1}')
  # Restore so the test is non-destructive.
  cp "$backup" "$SCRIPT_DIR/checksums.sha256"
  rm -f "$backup"

  if ((regen_exit != 0)); then
    fail "$1 [exit=0]" "exit=$regen_exit"
    return 0
  fi
  pass "$1 [exit=0]"

  local -- actual_hash
  actual_hash=$(sha256sum "$SCRIPT_DIR/rtfm" | cut -d' ' -f1)
  if [[ $new_hash_for_rtfm == "$actual_hash" ]]; then
    pass "$1 [rtfm hash matches sha256sum]"
  else
    fail "$1 [rtfm hash matches sha256sum]" \
      "regen=$new_hash_for_rtfm actual=$actual_hash"
  fi
}

t_checksums_missing_file_aborts() {
  if [[ ! -x $UPDATE_CHECKSUMS ]]; then
    skip "$1" 'update-checksums.sh not present'
    return 0
  fi
  # Build a sandbox dir, copy a modified update-checksums.sh that references
  # a non-existent file, ensure it exits non-zero.
  local -- sandbox
  sandbox=$(mktemp -d)
  # Minimal harness: rerun the real script from a directory missing 'rtfm'.
  cap_raw bash -c "cd '$sandbox' && '$UPDATE_CHECKSUMS'"
  rm -rf "$sandbox"
  if ((LAST_EXIT != 0)); then
    pass "$1 [non-zero on missing files]"
  else
    fail "$1 [non-zero on missing files]" "expected non-zero exit, got 0"
  fi
}

# --- 8. Static analysis (lint) -------------------------------------------

t_shellcheck() {
  if ! command -v shellcheck &>/dev/null; then
    skip "$1" 'shellcheck not installed'
    return 0
  fi
  cap_raw shellcheck "$RTFM" "$SCRIPT_DIR/rtfm.bash_completion" "$UPDATE_CHECKSUMS" "$SCRIPT_DIR/tests.bash"
  assert_exit 0 "$1 [shellcheck clean]"
}

t_syntax_check_rtfm() {
  cap_raw bash -n "$RTFM"
  assert_exit 0 "$1 [bash -n rtfm]"
}

t_syntax_check_completion() {
  cap_raw bash -n "$SCRIPT_DIR/rtfm.bash_completion"
  assert_exit 0 "$1 [bash -n rtfm.bash_completion]"
}

t_syntax_check_update_checksums() {
  cap_raw bash -n "$UPDATE_CHECKSUMS"
  assert_exit 0 "$1 [bash -n update-checksums.sh]"
}

# --- 9. Repository invariants --------------------------------------------

t_repo_has_fin_marker() {
  # Every shipped bash file should end with the '#fin' sentinel.
  local -- f
  local -i bad=0
  local -- bad_files=''
  for f in "$RTFM" "$UPDATE_CHECKSUMS" "$SCRIPT_DIR/rtfm.bash_completion" "$SCRIPT_DIR/tests.bash"; do
    if [[ $(tail -n 1 "$f") != '#fin' ]]; then
      ((++bad))
      bad_files+="$f "
    fi
  done
  if ((bad == 0)); then
    pass "$1"
  else
    fail "$1" "files missing '#fin': $bad_files"
  fi
}

t_repo_executable_bits() {
  local -- f
  local -i bad=0
  local -- bad_files=''
  for f in "$RTFM" "$UPDATE_CHECKSUMS" "$SCRIPT_DIR/tests.bash"; do
    [[ -x $f ]] || { ((++bad)); bad_files+="$f "; }
  done
  if ((bad == 0)); then
    pass "$1"
  else
    fail "$1" "files not executable: $bad_files"
  fi
}

t_repo_path_lockdown_present() {
  if grep -qE '^declare -rx PATH=/usr/local/bin:/usr/bin:/bin' "$RTFM"; then
    pass "$1"
  else
    fail "$1" "PATH lockdown line missing or mutated in rtfm"
  fi
}

# ====================================================================
# RUN
# ====================================================================

main() {
  say "${CYAN}rtfm test suite${NC}  —  script: $RTFM"
  [[ -z $FILTER ]] || say "  filter: ${YELLOW}$FILTER${NC}"

  [[ -x $RTFM ]] || { say "${RED}error:${NC} $RTFM is not executable"; exit 1; }

  section '1. Smoke / metadata'
  run_test 'version flag'                       t_version
  run_test 'version flag short -V'              t_version_short
  run_test 'help flag --help'                   t_help_long
  run_test 'help flag short -h'                 t_help_short
  run_test 'no args prints help to stderr'      t_no_args_shows_help

  section '2. Option parsing'
  run_test 'bad long option rejected'           t_bad_long_option
  run_test 'bad short option rejected'          t_bad_short_option
  run_test 'too many args rejected'             t_too_many_args
  run_test '-- separator terminates option parse' t_double_dash_terminates_options
  run_test '-- separator with valid command'    t_double_dash_with_valid_command
  run_test 'combined short flags -vq'           t_combined_short_flags_vq
  run_test 'combined short flags -qV'           t_combined_short_flags_qV

  section '3. Input validation'
  run_test 'validation: bare -- with no command' t_validation_empty_via_dash_dash
  run_test 'validation: semicolon rejected'     t_validation_metachar_semicolon
  run_test 'validation: dollar rejected'        t_validation_metachar_dollar
  run_test 'validation: backtick rejected'      t_validation_metachar_backtick
  run_test 'validation: pipe rejected'          t_validation_metachar_pipe
  run_test 'validation: redirect rejected'      t_validation_metachar_redirect
  run_test 'validation: glob rejected'          t_validation_metachar_glob
  run_test 'validation: path traversal rejected' t_validation_traversal
  run_test 'validation: slash rejected'         t_validation_slash
  run_test 'validation: dash prefix rejected'   t_validation_dash_prefix
  run_test 'validation: 65-char name rejected'  t_validation_too_long
  run_test 'validation: valid name with dot/digits accepted' t_validation_accepts_valid_chars
  run_test 'validation: valid name with plus accepted' t_validation_accepts_plus

  section '4. Source lookups'
  run_test 'lookup: bash builtin (declare)'     t_lookup_builtin
  run_test 'lookup: man page (ls)'              t_lookup_man
  run_test 'lookup: info page (coreutils)'      t_lookup_info
  run_test 'lookup: tldr page (rsync)'          t_lookup_tldr
  run_test 'lookup: multi-source concat (find)' t_lookup_multi_source_concat
  run_test 'lookup: unknown command, graceful miss' t_lookup_unknown_command
  run_test 'lookup: --help fallback path'       t_lookup_help_fallback

  section '5. Colour detection'
  run_test 'colour: NO_COLOR strips ANSI'       t_colour_no_color_strips_ansi
  run_test 'colour: FORCE_COLOR emits ANSI'     t_colour_force_color_emits_ansi
  run_test 'colour: CLICOLOR_FORCE emits ANSI'  t_colour_clicolor_force_emits_ansi
  run_test 'colour: non-TTY stdout strips ANSI' t_colour_redirect_strips_ansi
  run_test 'colour: NO_COLOR overrides FORCE_COLOR' t_colour_no_color_wins_over_force_color

  section '6. Exit-code contract'
  run_test 'exit codes: documented contract'    t_exit_codes_summary

  section '7. update-checksums.sh'
  run_test 'checksums: regenerates and matches sha256sum' t_checksums_regenerates
  run_test 'checksums: missing files cause non-zero exit' t_checksums_missing_file_aborts

  section '8. Static analysis'
  run_test 'lint: shellcheck clean'             t_shellcheck
  run_test 'syntax: bash -n rtfm'               t_syntax_check_rtfm
  run_test 'syntax: bash -n rtfm.bash_completion' t_syntax_check_completion
  run_test 'syntax: bash -n update-checksums.sh' t_syntax_check_update_checksums

  section '9. Repository invariants'
  run_test 'invariant: shipped scripts end with #fin' t_repo_has_fin_marker
  run_test 'invariant: shipped scripts are executable' t_repo_executable_bits
  run_test 'invariant: PATH lockdown line present in rtfm' t_repo_path_lockdown_present

  # --- Summary -----------------------------------------------------------
  say ''
  say "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  say "Tests run: ${TESTS_RUN}  ${GREEN}pass: ${TESTS_PASS}${NC}  ${RED}fail: ${TESTS_FAIL}${NC}  ${YELLOW}skip: ${TESTS_SKIP}${NC}"
  if ((TESTS_FAIL > 0)); then
    say ''
    say "${RED}Failures:${NC}"
    local -- f
    for f in "${FAILURES[@]}"; do say "  - $f"; done
    exit 1
  fi
  ((TESTS_RUN > 0)) || { say "${YELLOW}No tests matched filter ${FILTER@Q}${NC}"; exit 2; }
  exit 0
}

main "$@"

#fin
