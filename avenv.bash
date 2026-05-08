avenv() {
    local original_dir="$PWD"

    if [ "$1" == "help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        echo "Usage: avenv [command] or avenv [dir]"
        echo "Commands:"
        echo "  (no command)  Find and activate a virtual environment in parent directories."
        echo "  [dir]         Find and activate a virtual environment starting from [dir]."
        echo "  new [name]    Create a new virtual environment (default name: .venv)."
        echo "  fix           Attempt to repair a broken virtual environment."
        echo "  findall [dir] Find all virtual environments in a directory (default: \$HOME)."
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

    if [ "$1" == "findall" ]; then
        local default_dir="${HOME:-/home/$USER}"
        local search_dir="${2:-$default_dir}"

        if [ ! -d "$search_dir" ]; then
            echo -e "\033[31mError: Directory '$search_dir' does not exist.\033[0m"
            return 1
        fi

        echo -e "\033[33mWarning:\033[0m Scanning \033[36m$search_dir\033[0m might take a significant amount of time."
        read -p "Do you want to continue? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
            echo "Operation cancelled."
            return 0
        fi

        echo -e "Initializing scanner..."
        
        local results_file=$(mktemp)
        local progress_file=$(mktemp)
        local current_dir_file=$(mktemp)
        local start_time=$(date +%s)
        
        # Disable monitor mode to avoid background job completion spam
        local monitor_enabled=0
        if [[ "$-" == *m* ]]; then
            monitor_enabled=1
            set +m
        fi
        # Safely handle zsh-specific monitor setting if present
        if type unsetopt &>/dev/null; then
            unsetopt monitor 2>/dev/null
        fi
        
        local worker_pid=""
        
        # Cleanup trap for graceful CTRL-C
        trap 'tput cnorm 2>/dev/null; [ "$monitor_enabled" -eq 1 ] && set -m; if type setopt &>/dev/null && [ "$monitor_enabled" -eq 1 ]; then setopt monitor 2>/dev/null; fi; rm -f "$results_file" "$progress_file" "$current_dir_file"; [ -n "$worker_pid" ] && kill $worker_pid 2>/dev/null; echo -e "\n\033[31mScan aborted by user.\033[0m"; trap - INT; return 1' INT
        
        # Gather top-level directories to calculate accurate progress
        local top_dirs=()
        while IFS= read -r -d $'\0'; do
            top_dirs+=("$REPLY")
        done < <(find "$search_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null -print0)
        
        local total_dirs=${#top_dirs[@]}
        
        # Fallback if no subdirs exist
        if [ "$total_dirs" -eq 0 ]; then
            top_dirs=("$search_dir")
            total_dirs=1
        fi

        tput civis 2>/dev/null || true # Hide cursor
        
        # Start a single background worker to prevent shell job spam per directory
        (
            for d in "${top_dirs[@]}"; do
                echo "$d" > "$current_dir_file"
                find "$d" -type f -path "*/bin/activate" 2>/dev/null >> "$results_file"
                echo "1" >> "$progress_file"
            done
        ) &
        worker_pid=$!
        
        # ASCII spinner animation frames
        local spinner=( "-" "\\" "|" "/" )
        local spin_idx=0
        local current_dir_idx=0
        local found_count=0
        
        while kill -0 $worker_pid 2>/dev/null; do
            current_dir_idx=$(wc -l < "$progress_file" 2>/dev/null || echo 0)
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            
            # Calculate ETA using integer math
            local eta=0
            if [ "$current_dir_idx" -gt 0 ] && [ "$elapsed" -gt 0 ]; then
                local time_per_dir_ms=$(( (elapsed * 1000) / current_dir_idx ))
                local remaining_dirs=$((total_dirs - current_dir_idx))
                eta=$(( (time_per_dir_ms * remaining_dirs) / 1000 ))
            fi
            
            local eta_formatted=$(printf "%02d:%02d" $((eta / 60)) $((eta % 60)))
            local elp_formatted=$(printf "%02d:%02d" $((elapsed / 60)) $((elapsed % 60)))
            
            # ASCII Progress Bar (25 blocks wide) using safe characters
            local percent=$(( (current_dir_idx * 100) / total_dirs ))
            # Prevent edge-case divide by zero or negative calculations
            [ "$percent" -gt 100 ] && percent=100
            local filled=$((percent / 4))
            local empty=$((25 - filled))
            local bar=$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s" | tr ' ' '-')
            
            # Fast line count for live results
            found_count=$(wc -l < "$results_file" 2>/dev/null || echo 0)
            
            local spin_char=${spinner[$((spin_idx % 4))]}
            ((spin_idx++))
            
            local current_scanning=$(cat "$current_dir_file" 2>/dev/null || echo "...")
            local display_dir=$(basename "$current_scanning")
            if [ ${#display_dir} -gt 15 ]; then
                display_dir="${display_dir:0:12}..."
            fi
            
            # Render the UI (overwrites current line using \r)
            printf "\r\033[K%s Scanning [%s] %3d%% | ⏱️ ELP: %s | 🎯 ETA: %s | 📦 Found: %d | 🔍 %-15s" \
                "$spin_char" "$bar" "$percent" "$elp_formatted" "$eta_formatted" "$found_count" "$display_dir"
                
            sleep 0.2
        done
        wait $worker_pid 2>/dev/null
        
        # Reset terminal and traps
        trap - INT
        tput cnorm 2>/dev/null || true
        if [ "$monitor_enabled" -eq 1 ]; then
            set -m
            if type setopt &>/dev/null; then
                setopt monitor 2>/dev/null
            fi
        fi
        
        found_count=$(wc -l < "$results_file" 2>/dev/null || echo 0)
        local total_time=$(( $(date +%s) - start_time ))
        local tt_formatted=$(printf "%02d:%02d" $((total_time / 60)) $((total_time % 60)))
        
        # Ensure we completely clear the active line before printing the success message
        printf "\r\033[K✨ \033[32mScan complete in %s!\033[0m Found \033[36m%d\033[0m virtual environments.\n\n" "$tt_formatted" "$found_count"
        
        if [ "$found_count" -gt 0 ]; then
            echo -e "\033[1mDiscovered Environments:\033[0m"
            echo "--------------------------------------------------------"
            sort "$results_file" | while IFS= read -r env_path; do
                local env_dir="${env_path%/bin/activate}"
                echo -e "📁 \033[34m$env_dir\033[0m"
            done
            echo "--------------------------------------------------------"
            echo -e "Tip: Use 'cd' to navigate to one of these directories and run 'avenv'."
        fi
        
        rm -f "$results_file" "$progress_file" "$current_dir_file"
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

    local target_dir="$original_dir"
    local cmd_fix=0

    # Parse remaining arguments (remote directory or fix)
    if [ "$1" == "fix" ]; then
        cmd_fix=1
    elif [ -n "$1" ]; then
        if [ -d "$1" ]; then
            target_dir=$(cd "$1" 2>/dev/null && pwd)
        else
            echo -e "\033[31mError: Unknown command or directory not found: '$1'\033[0m"
            echo "Usage: avenv [command] or avenv [dir]"
            return 1
        fi
    fi

    local venv_path
    venv_path=$(_find_venv "$target_dir")
    if [ -z "$venv_path" ]; then
        echo -e "No virtual environment found starting from: $target_dir\nTo create one, use: avenv new [name]"
        return 1
    fi

    if [ "$cmd_fix" -eq 1 ]; then
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
