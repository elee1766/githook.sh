# git helpers

githook_check_git_repository() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        githook_error "not a git repository"
    fi
    git rev-parse --show-toplevel
}

# figures out the path to this script, even if symlinked
githook_get_script_path() {
    if [ -L "$0" ]; then
        if command -v readlink >/dev/null 2>&1; then
            readlink -f "$0" 2>/dev/null || {
                # bsd doesn't have readlink -f
                _target="$(readlink "$0")"
                if [ "${_target#/}" = "$_target" ]; then
                    echo "$(cd "$(dirname "$0")" && pwd)/$_target"
                else
                    echo "$_target"
                fi
            }
        else
            echo "$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
        fi
    else
        echo "$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    fi
}
