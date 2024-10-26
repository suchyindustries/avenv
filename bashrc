# Add this to the end of your .bashrc file in your HOME directory
avenv() {
  local original_dir="$PWD"
  local current_dir="$original_dir"
  local found=false

  # Handle 'new' flag for creating virtual environments
  if [ "$1" == "new" ]; then
    local env_name=".venv"

    # If a name is provided, use it
    if [ -n "$2" ]; then
      env_name="$2"
    fi

    # Create a virtual environment with the specified name
    python -m venv "$current_dir/$env_name"

    # Activate the newly created virtual environment
    source "$current_dir/$env_name/bin/activate"
    return
  fi

  # Default behavior: search for a virtual environment in current or parent directories
  while true; do
    # Check if any folder in current directory has a typical venv folder structure
    for dir in "$current_dir"/.venv "$current_dir"/*; do
      if [ -d "$dir/bin" ] && [ -f "$dir/bin/activate" ]; then
        # Activate the virtual environment
        source "$dir/bin/activate"
        found=true
        break 2
      fi
    done

    # Move to the parent directory
    parent_dir=$(dirname "$current_dir")

    # If reached the root directory, stop searching
    if [ "$parent_dir" == "$current_dir" ]; then
      break
    fi

    current_dir="$parent_dir"
  done

  # Return to the original directory
  cd "$original_dir"

  # If no venv found
  if [ "$found" == false ]; then
    echo -e "No virtual environment found with the typical venv folder structure in the current or any parent directory.\nTo create a new one, use 'avenv new [envname]'."
  fi
}
