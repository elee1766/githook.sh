# utility functions

githook_error() {
    echo "error: $1" >&2
    exit 1
}

githook_warn() {
    echo "warning: $1" >&2
}

githook_info() {
    echo "$1"
}

githook_debug() {
    if githook_is_debug_enabled; then
        echo "debug: $1" >&2
    fi
}

githook_is_debug_enabled() {
    case "${GITHOOK_DEBUG:-}" in
        1|true|True|TRUE|yes|Yes|YES|on|On|ON) return 0 ;;
        *) return 1 ;;
    esac
}

githook_is_disabled() {
    case "${GITHOOK_DISABLE:-}" in
        1|true|True|TRUE|yes|Yes|YES|on|On|ON) return 0 ;;
        *) return 1 ;;
    esac
}

githook_is_valid_hook() {
    _hook_name="$1"
    for _valid_hook in $GITHOOK_SUPPORTED_HOOKS; do
        if [ "$_hook_name" = "$_valid_hook" ]; then
            return 0
        fi
    done
    return 1
}
