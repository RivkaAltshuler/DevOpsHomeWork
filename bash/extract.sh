# sudo apt install ncompress
declare -A EXTRACT_COMMANDS=(
  ["gzip compressed"]="gunzip -f"
  ["bzip2 compressed"]="bunzip2 -f"
  ["Zip archive"]="unzip -o"
  ["compress'd data"]="uncompress -f"
  # Add more archive types here as needed...

)
decompressed_count=0
skipped_count=0

extract_single_file() {
  local file="$1"  
  
  if [[ ! -f "$file" ]]; then
    my_echo "Error: File '$file' not found."
    return 1
  fi

  file_type=$(file -b "$file")
  
  local command
  
  for key in "${!EXTRACT_COMMANDS[@]}"; do
    if [[ "$file_type" == *"$key"* ]]; then
      command="${EXTRACT_COMMANDS[$key]}"
      break  
    fi
  done
  
  if [[ -z "$command" ]]; then  # no appropiate compression -> skip
    skipped_count=$((skipped_count + 1))
	my_echo "file $file not decompressed"
    return 0 
  fi
  
  # uncompress:
  eval "$command" "$file" || { my_echo "Error compressing file!"; exit 1; }
  decompressed_count=$((decompressed_count + 1))
  if [[ "$verbose" -eq 1 ]]; then
    my_echo "file $file decompressed"
  fi
  

}

my_echo() {
  if [[ "$verbose" -eq 1 ]]; then
    echo $1
  fi
}



extract()  {
  local file=$1
  
  if [[ -d "$file" ]]; then
  
    while IFS= read -r -d $'\0' current_file; do
	  if [[ -d "$current_file" && "$recursive" -eq 1 ]]; then
         extract "$current_file" $recursive
	  else
	     extract_single_file "$current_file"
	  fi
    done < <(find "$file" -type f -print0)
	
  elif [[ -f "$file" ]]; then
    extract_single_file "$file"
  else
    echo "Error: '$file' is not a file or directory."
  fi
}

print_help() {
  echo "Usage: extract [-h] [-r] [-v] file [file...]"
  echo "Given a list of filenames as input, this script queries each"
  echo "target file (parsing the output of the 'file' command) for the"
  echo "type of compression used on it. Then the script automatically"
  echo "invokes the appropriate decompression command, putting files in"
  echo "the same folder. If files with the same name already exist,"
  echo "they are overwritten."
  echo "Unpack should support gunzip, bunzip2, unzip, uncompress, tar, xz, 7zip, rar." # Added more formats
  echo ""  # Add an empty line for better readability
  echo "Options:"
  echo "  -h  Help: Display this help message."
  echo "  -r  Recursive: Traverse subdirectories recursively."
  echo "  -v  Verbose: Print details of each file processed."
  echo "" # Add an empty line for better readability
  echo "Examples:"
  echo "  extract file.zip"
  echo "  extract directory -r"
  echo "  extract file1.gz file2.bz2 directory1 -rv"
}

# Main script logic
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h)
      print_help
	  exit 0
      ;;
    -r)
      recursive=1
      shift
      ;;
    -v)
      verbose=1
      shift
      ;;
    *)
   
	  extract "$1"
	  
      shift
      ;;
  esac
done

echo "Archives decompressed: $decompressed_count"
echo "Files not decompressed: $skipped_count"
exit 0