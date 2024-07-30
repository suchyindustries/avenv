# add these to end of .bashrc file in your HOME dir
avenv() {
  local original_dir="$PWD"
  local current_dir="$original_dir"
  local found=false

  while true; do
    # Check if .venv folder exists in the current directory
    if [ -d "$current_dir/.venv" ]; then
      # Activate the virtual environment
      source "$current_dir/.venv/bin/activate"
      found=true
      break
    else
      # Move to the parent directory
      parent_dir=$(dirname "$current_dir")

      # If reached the root directory, stop searching
      if [ "$parent_dir" == "/" ]; then
        break
      fi

      current_dir="$parent_dir"
      cd "$current_dir"
    fi
  done

  # Return to the original directory
  cd "$original_dir"

  # If .venv not found
  if [ "$found" == false ]; then
    echo "The .venv folder does not exist in the current or any parent directory."
  fi
}
