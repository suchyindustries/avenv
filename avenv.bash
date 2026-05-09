# Global helper for bottom-right UI to prevent "command not found" errors
_avenv_render_corner() {
    # Only draw if we are in an active avenv session with bottomright enabled
    if [ -n "$VIRTUAL_ENV" ] && [ "$_AVENV_CORNER_ENABLED" == "true" ]; then
        local cols=$(tput cols 2>/dev/null || echo 80)
        local lines=$(tput lines 2>/dev/null || echo 24)
        local text="($_AVENV_NAME)"
        tput sc # Save cursor
        tput cup $((lines - 1)) $((cols - ${#text}))
        echo -ne "\033[36m$text\033[0m"
        tput rc # Restore cursor
    fi
}

avenv() {
    local original_dir="$PWD"
    
    # ---------------------------------------------------------
    # CONFIGURATION LOADER
    # ---------------------------------------------------------
    local CONFIG_FILE="$HOME/.config/avenv.conf"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$HOME/.config" 2>/dev/null
        curl -fsSL -o "$CONFIG_FILE" "https://raw.githubusercontent.com/suchyindustries/avenv/main/avenv.conf" 2>/dev/null || {
            echo "env_version_checks = true" > "$CONFIG_FILE"
            echo "shut_up = false" >> "$CONFIG_FILE"
            echo "prefix = true" >> "$CONFIG_FILE"
        }
    fi

    local CONF_CHECKS="true"
    local CONF_SHUTUP="false"
    local CONF_PREFIX="true"

    if [ -f "$CONFIG_FILE" ]; then
        CONF_CHECKS=$(grep -E "^[[:space:]]*env_version_checks" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' "[:space:]')
        CONF_SHUTUP=$(grep -E "^[[:space:]]*shut_up" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' "[:space:]')
        CONF_PREFIX=$(grep -E "^[[:space:]]*prefix" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' "[:space:]')
    fi

    av_echo() { [ "$CONF_SHUTUP" != "true" ] && echo -e "$@"; }
    av_printf() { [ "$CONF_SHUTUP" != "true" ] && printf "$@"; }
    
    # Find newest Python 3
    local SYS_PYTHON=""
    for v in {20..6}; do
        if command -v "python3.$v" >/dev/null 2>&1; then
            SYS_PYTHON="python3.$v"
            break
        fi
    done
    [ -z "$SYS_PYTHON" ] && SYS_PYTHON="python3"

    # Command: Help
    if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: avenv [command] or avenv [dir]"
        echo "Commands:"
        echo "  (no command)  Find and activate venv in parent directories."
        echo "  [dir]         Activate venv at [dir] or search within it."
        echo "  new [name]    Create new venv (default: .venv)."
        echo "  fix           Repair broken venv."
        echo "  update [xxx]  Update python, pip, or package."
        echo "  findall [dir] Search all venvs globally."
        echo "  deactivate    Deactivate current venv."
        return 0
    fi

    # Command: Deactivate
    if [ "$1" == "deactivate" ]; then
        if type deactivate &>/dev/null; then
            deactivate
        else
            av_echo "No active virtual environment."
        fi
        return 0
    fi

    # Command: New
    if [ "$1" == "new" ]; then
        local env_name="${2:-.venv}"
        if ! command -v "$SYS_PYTHON" &>/dev/null; then
            av_echo "\033[31mError:\033[0m Python not found. Install $SYS_PYTHON!"
            return 1
        fi
        av_echo "Creating venv '$env_name' using $SYS_PYTHON..."
        if "$SYS_PYTHON" -m venv "$original_dir/$env_name"; then
            avenv "$original_dir/$env_name"
        else
            av_echo "\033[31mError:\033[0m Failed to create venv."
            return 1
        fi
        return 0
    fi

    # Command: Findall
    if [ "$1" == "findall" ]; then
        local search_dir="${2:-$HOME}"
        [ ! -d "$search_dir" ] && { av_echo "\033[31mError: '$search_dir' not found.\033[0m"; return 1; }

        if [ "$CONF_SHUTUP" != "true" ]; then
            av_echo "\033[33mWarning:\033[0m Scanning \033[36m$search_dir\033[0m may take time."
            read -p "Continue? (Y/n) " -n 1 -r; echo
            [[ ! $REPLY =~ ^[Yy]$ && -n $REPLY ]] && return 0
        fi

        local results_file=$(mktemp); local progress_file=$(mktemp); local cur_file=$(mktemp)
        local start_t=$(date +%s); local worker_pid=""
        
        local mon=0; [[ "$-" == *m* ]] && { mon=1; set +m; }
        trap 'tput cnorm 2>/dev/null; [ $mon -eq 1 ] && set -m; rm -f "$results_file" "$progress_file" "$cur_file"; [ -n "$worker_pid" ] && kill $worker_pid 2>/dev/null; av_echo "\n\033[31mScan aborted.\033[0m"; trap - INT; return 1' INT
        
        local top_dirs=(); while IFS= read -r -d $'\0'; do top_dirs+=("$REPLY"); done < <(find "$search_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null -print0)
        local total_dirs=${#top_dirs[@]}; [ $total_dirs -eq 0 ] && { top_dirs=("$search_dir"); total_dirs=1; }

        tput civis 2>/dev/null
        ( for d in "${top_dirs[@]}"; do echo "$d" > "$cur_file"; find "$d" -type f -path "*/bin/activate" 2>/dev/null >> "$results_file"; echo "1" >> "$progress_file"; done ) &
        worker_pid=$!
        
        local spinner=( "-" "\\" "|" "/" ); local s_idx=0
        while kill -0 $worker_pid 2>/dev/null; do
            local done_dirs=$(wc -l < "$progress_file" 2>/dev/null || echo 0)
            local elp=$(( $(date +%s) - start_t ))
            local eta=0; [ $done_dirs -gt 0 ] && eta=$(( (elp * (total_dirs - done_dirs)) / done_dirs ))
            local bar_pc=$(( (done_dirs * 100) / total_dirs ))
            local filled=$((bar_pc / 4)); local bar=$(printf "%${filled}s" | tr ' ' '#')$(printf "%$((25-filled))s" | tr ' ' '-')
            local found=$(wc -l < "$results_file" 2>/dev/null || echo 0)
            local cur_d=$(basename "$(cat "$cur_file" 2>/dev/null || echo "...")")
            av_printf "\r\033[K%s Scanning [%s] %3d%% | ELP: %02d:%02d | ETA: %02d:%02d | Found: %d | 🔍 %-12.12s" \
                "${spinner[$((s_idx++ % 4))]}" "$bar" "$bar_pc" $((elp/60)) $((elp%60)) $((eta/60)) $((eta%60)) "$found" "$cur_d"
            sleep 0.2
        done
        wait $worker_pid 2>/dev/null
        
        tput cnorm 2>/dev/null; [ $mon -eq 1 ] && set -m; trap - INT
        found=$(wc -l < "$results_file" 2>/dev/null || echo 0)
        av_printf "\r\033[K✨ \033[32mScan complete in %ds!\033[0m Found \033[36m%d\033[0m venvs.\n\n" $(( $(date +%s) - start_t )) "$found"
        [ $found -gt 0 ] && { sort "$results_file" | sed 's|/bin/activate||' | xargs -I{} echo -e "📁 \033[34m{}\033[0m"; }
        rm -f "$results_file" "$progress_file" "$cur_file"
        return 0
    fi

    # Venv Search Logic
    _find_venv() {
        local s_path="$1"
        # 1. Direct Hit Check
        [ -f "$s_path/bin/activate" ] && { echo "$s_path"; return 0; }
        
        # 2. Search Subdirectories (depth 2 allows .venv inside path)
        local found=$(find "$s_path" -maxdepth 2 -type f -path "*/bin/activate" 2>/dev/null | head -n 1)
        [ -n "$found" ] && { echo "${found%/bin/activate}"; return 0; }
        
        # 3. Parent Traversal (Only if searching from current working directory)
        if [[ "$s_path" == "$PWD" || "$s_path" == "." ]]; then
            local curr="$PWD"
            while true; do
                for d in "$curr"/* "$curr"/.*; do
                    [ -d "$d" ] && [ -f "$d/bin/activate" ] && { echo "$d"; return 0; }
                done
                local p_dir=$(dirname "$curr")
                [ "$p_dir" == "$curr" ] && break
                curr="$p_dir"
            done
        fi
        return 1
    }

    local target_dir="$original_dir"
    local is_fix=0; local is_upd=0; local upd_pkg=""

    if [ "$1" == "fix" ]; then is_fix=1
    elif [ "$1" == "update" ]; then is_fix=1; is_upd=1; upd_pkg="$2"
    elif [ -n "$1" ]; then
        if [ -d "$1" ]; then
            target_dir=$(cd "$1" &>/dev/null && pwd)
        else
             # If it's not a dir and not a command, maybe it's a venv name
             target_dir="$original_dir/$1"
        fi
    fi

    local v_path=$(_find_venv "$target_dir")
    [ -z "$v_path" ] && { av_echo "No venv found at $target_dir."; return 1; }

    # Command: Fix / Update
    if [ $is_fix -eq 1 ]; then
        if [ $is_upd -eq 1 ] && [ -n "$upd_pkg" ] && [ "$upd_pkg" != "python" ] && [ "$upd_pkg" != "all" ]; then
            if [ "$upd_pkg" == "pip" ]; then
                av_echo "Updating pip in $v_path..."
                "$v_path/bin/python" -m pip install --upgrade pip >/dev/null 2>&1
            else
                av_echo "Updating package '$upd_pkg' in $v_path..."
                "$v_path/bin/python" -m pip install --upgrade "$upd_pkg" >/dev/null 2>&1
            fi
            cd "$original_dir"
            return 0
        fi

        av_echo "Processing venv: $v_path"
        local reqs=$(mktemp)
        "$v_path/bin/python" -m pip freeze > "$reqs" 2>/dev/null
        
        local go="y"
        [ "$CONF_SHUTUP" != "true" ] && { read -p "Recreate venv with $SYS_PYTHON? (y/N) " -n 1 -r; echo; go=$REPLY; }
        
        if [[ $go =~ ^[Yy]$ ]]; then
            rm -rf "$v_path" && "$SYS_PYTHON" -m venv "$v_path"
            if [ -s "$reqs" ]; then
                av_echo "Restoring packages..."
                if [ "$is_upd" -eq 1 ]; then
                    cut -d= -f1 "$reqs" | xargs -n1 "$v_path/bin/python" -m pip install --upgrade >/dev/null 2>&1
                else
                    "$v_path/bin/pip" install -r "$reqs" >/dev/null 2>&1
                fi
            fi
            av_echo "Done!"
        fi
        rm -f "$reqs"
        return 0
    fi

    # Activation Logic
    local pip_o=0; local p_out=()
    local skipped_checks=0
    
    if [ "$CONF_CHECKS" == "true" ]; then
        av_printf "Activating: $v_path ... \033[33m(Checking updates - press SPACE to skip)\033[0m\r"
        local check_results=$(mktemp)
        
        # Run pip check in background to allow interruption
        (
            local t_pip_o=0; local t_p_out=()
            local o_list=$("$v_path/bin/python" -m pip list --outdated --disable-pip-version-check 2>/dev/null | tail -n +3)
            while read -r l; do
                local p=$(echo "$l" | awk '{print $1}')
                [ "$p" == "pip" ] && t_pip_o=1 || [ -n "$p" ] && t_p_out+=("$p")
            done <<< "$o_list"
            echo "pip_o=$t_pip_o" > "$check_results"
            echo "p_out=(${t_p_out[@]})" >> "$check_results"
        ) &
        local check_pid=$!
        
        # Wait for background job or spacebar
        while kill -0 $check_pid 2>/dev/null; do
            if read -t 0.1 -s -n 1 key 2>/dev/null; then
                if [[ "$key" == " " ]]; then
                    skipped_checks=1
                    kill $check_pid 2>/dev/null
                    break
                fi
            fi
        done
        wait $check_pid 2>/dev/null
        
        if [ $skipped_checks -eq 0 ] && [ -f "$check_results" ]; then
            source "$check_results" 2>/dev/null
        fi
        rm -f "$check_results"
    fi
    av_printf "\r\033[K" # Clear line

    local v_py=$("$v_path/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
    local s_py=$("$SYS_PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
    
    local diff=0
    if [ -n "$v_py" ] && [ -n "$s_py" ]; then
        diff=$(( ${s_py#*.} - ${v_py#*.} ))
    fi
    local c="\033[32m"; [ $diff -eq 1 ] && c="\033[33m"; [ $diff -ge 2 ] && c="\033[31m"

    local skip_msg=""
    [ $skipped_checks -eq 1 ] && skip_msg=" \033[90m(Skipped)\033[0m"

    av_echo "Activating: $v_path [${c}python$v_py\033[0m]$skip_msg"
    [ $diff -gt 0 ] && av_echo "Newer [\033[32mpython$s_py\033[0m] available. Run 'avenv update python'."
    
    if [ $skipped_checks -eq 0 ]; then
        [ $pip_o -eq 1 ] && av_echo "Warning: [\033[33mpip\033[0m] is outdated. Run 'avenv update pip'."
        [ ${#p_out[@]} -gt 0 ] && av_echo "Warning: \033[33m${#p_out[@]}\033[0m packages outdated. Run 'avenv update'."
    fi

    # Set prompt style
    export VIRTUAL_ENV_DISABLE_PROMPT=1
    case "$CONF_PREFIX" in
        false) source "$v_path/bin/activate" ;;
        short) 
            source "$v_path/bin/activate"
            local sn=$(basename "$v_path"); PS1="(${sn:0:5}) $PS1" ;;
        bottomright)
            export _AVENV_NAME=$(basename "$v_path")
            export _AVENV_CORNER_ENABLED="true"
            # Hook PROMPT_COMMAND for Bash
            if [[ ! "$PROMPT_COMMAND" =~ "_avenv_render_corner" ]]; then
                export _OLD_PC="$PROMPT_COMMAND"
                PROMPT_COMMAND="_avenv_render_corner${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
            fi
            source "$v_path/bin/activate"
            
            # Robust function cloning: rename 'deactivate' to '_avenv_orig_deactivate'
            eval "$(declare -f deactivate | sed '1s/^deactivate/_avenv_orig_deactivate/')"
            
            # New deactivate wrapper
            deactivate() {
                # Clear the corner text
                local lines=$(tput lines 2>/dev/null || echo 24)
                tput sc; tput cup $((lines - 1)) 0; tput el; tput rc
                
                # Restore shell state
                PROMPT_COMMAND="$_OLD_PC"
                unset _AVENV_CORNER_ENABLED _AVENV_NAME _OLD_PC
                
                # Call original deactivate logic
                _avenv_orig_deactivate "$@"
                
                # Self-destruct the wrapper and the clone
                unset -f _avenv_orig_deactivate deactivate 2>/dev/null
            }
            ;;
        *) unset VIRTUAL_ENV_DISABLE_PROMPT; source "$v_path/bin/activate" ;;
    esac
    
    cd "$original_dir"
}

# Ensure helper is exported for subshells
export -f _avenv_render_corner
