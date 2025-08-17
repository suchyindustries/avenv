avenv() {
    local original_dir="$PWD"

    if [ "$1" == "help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        echo "Usage: avenv [command]"
        echo "Commands:"
        echo "  (no command)  Find and activate a virtual environment in parent directories."
        echo "  new [name]    Create a new virtual environment (default name: .venv)."
        echo "  fix           Attempt to repair a broken virtual environment."
        echo "  deactivate    Deactivate the current virtual environment."
        echo "  help          Show this help message."
        return 0
    fi

    if [ "$1" == "deactivate" ]; then
        if type deactivate &>/dev/null; then
            deactivate
        else
            echo "No active virtual environment to deactivate."
        fi
        return 0
    fi

    if [ "$1" == "new" ]; then
        local env_name=".venv"
        if [ -n "$2" ]; then
            env_name="$2"
        fi
        if ! command -v python3 &> /dev/null; then
            echo "Error: python3 command not found. Cannot create virtual environment."
            return 1
        fi
        echo "Creating virtual environment '$env_name'..."
        if python3 -m venv "$original_dir/$env_name"; then
            echo "Activating '$env_name'..."
            source "$original_dir/$env_name/bin/activate"
        else
            echo "Error: Failed to create virtual environment."
            return 1
        fi
        return 0
    fi

    _find_venv() {
        local search_dir="$1"
        while true; do
            for dir in "$search_dir"/* "$search_dir"/.*; do
                if [ -d "$dir" ] && [ -f "$dir/bin/activate" ]; then
                    echo "$dir"
                    return 0
                fi
            done
            local parent_dir
            parent_dir=$(dirname "$search_dir")
            if [ "$parent_dir" == "$search_dir" ]; then
                return 1
            fi
            search_dir="$parent_dir"
        done
    }

    local venv_path
    venv_path=$(_find_venv "$original_dir")
    if [ -z "$venv_path" ]; then
        echo -e "No virtual environment found.\nTo create one, use: avenv new [name]"
        return 1
    fi

    if [ "$1" == "fix" ]; then
        echo "Found virtual environment at: $venv_path"
        local pyvenv_cfg_path="$venv_path/pyvenv.cfg"
        if [ -f "$pyvenv_cfg_path" ]; then
            local python_executable
            python_executable=$(command -v python3)
            if [ -z "$python_executable" ]; then
                echo "Warning: Could not find 'python3' executable to verify pyvenv.cfg."
            else
                local command_in_cfg
                command_in_cfg=$(grep "^command" "$pyvenv_cfg_path" | cut -d '=' -f 2- | sed 's/^[ \t]*//;s/[ \t]*$//')
                local expected_command="$python_executable -m venv $venv_path"
                if [ "$command_in_cfg" != "$expected_command" ]; then
                    echo "Warning: The venv seems to have been moved."
                    echo "  Expected creation command: $expected_command"
                    echo "  Actual creation command: $command_in_cfg"
                else
                    echo "The 'command' in pyvenv.cfg looks correct."
                fi
            fi
        else
            echo "Warning: pyvenv.cfg not found."
        fi
        echo "Freezing installed packages..."
        local requirements_file
        requirements_file=$(mktemp)
        if ! "$venv_path/bin/python" -m pip freeze > "$requirements_file"; then
            echo "Error: Failed to freeze packages. Is pip working?"
            rm "$requirements_file"
            return 1
        fi
        if [ ! -s "$requirements_file" ]; then
            echo "No packages found to reinstall."
            rm "$requirements_file"
            read -p "The environment is empty. Recreate it? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Recreating environment..."
                rm -rf "$venv_path"
                python3 -m venv "$venv_path"
                echo "Environment recreated."
            fi
            return 0
        fi
        echo "Found the following packages:"
        cat "$requirements_file"
        echo
        read -p "Reinstall these packages to fix the environment? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Fixing environment by recreating it and reinstalling packages..."
            rm -rf "$venv_path"
            python3 -m venv "$venv_path"
            if "$venv_path/bin/pip" install -r "$requirements_file"; then
                echo "Environment fixed successfully."
            else
                echo "Error: Failed to reinstall packages."
            fi
        fi
        rm "$requirements_file"
    else
        echo "Activating: $venv_path"
        source "$venv_path/bin/activate"
    fi

    cd "$original_dir"
}
