#!/bin/bash

check_syntax() {
  local dir="${1:-.}"  # Default to current directory if none provided
  local -i errors=0

  local -a Files
  readarray -t Files < <(find "$dir" -type f \
    -not -path "*/.gudang/*" \
    -not -path "*/.venv/*" \
    -not -path "*/__*" \
    -not -path "*/.git*" \
    -not -path "*/temp/*" \
    -not -path "*/~*" \
    -not -path "*/.~*" \
    -not -path "*/.*" \
    -not -path "*/*.md" \
    -not -path "*/*.pdf" \
    -not -path "*/*.PDF" \
    -not -path "*/*.mp3" \
    -not -path "*/*.mp4" \
    -not -path "*/*.png" \
    -not -path "*/*.jpg" \
    -not -path "*/*.zip" \
    -not -path "*/*.gz" \
    -not -path "*/*.pyc" \
    -not -path "*/*.bak" \
    
    )
    
  local file ftype
  for file in "${Files[@]}"; do
    ftype=$(filetype "$file")
    echo "$ftype | $file" 
    if [[ $ftype == 'bash' || $ftype == 'sh' ]]; then
      echo -n "Checking $file: "
      if bash -n "$file" > /dev/null 2>&1; then
        echo -e "\e[32mOK\e[0m"
      else
        errors+=1
        echo -e "\e[31mFAILED\e[0m"
        bash -n "$file"
      fi

    elif [[ $ftype == 'python' || $ftype == 'py' ]]; then
      echo -n "Checking $file: "
      if python3 -m py_compile "$file" > /dev/null 2>&1; then
        echo -e "\e[32mOK\e[0m"
      else
        errors+=1
        echo -e "\e[31mFAILED\e[0m"
        python3 -m py_compile "$file"
      fi

    elif [[ $ftype == 'php' ]]; then
      echo -n "Checking $file: "
      if php -l "$file" > /dev/null 2>&1; then
        echo -e "\e[32mOK\e[0m"
      else
        errors+=1
        echo -e "\e[31mFAILED\e[0m"
        php -l "$file"
      fi
 
    elif [[ ! ($ftype == 'text' || $ftype == 'binary') ]]; then
      echo '??'   
    fi
  done
  
  echo -e "\nSyntax check complete"
  ((errors)) && {
    echo "Errors were found in $errors files"
    return 1
  }
  return 0
}

check_syntax "$@"
