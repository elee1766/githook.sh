# main entry point

githook_main() {
    # default: init if not installed, otherwise help
    if [ -z "${1:-}" ]; then
        _git_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
        if [ -n "$_git_root" ] && [ -f "$_git_root/githook.sh" ]; then
            _command="help"
        else
            _command="init"
        fi
    else
        _command="$1"
    fi

    case "$_command" in
        init)      githook_cmd_init ;;
        install)   githook_cmd_install ;;
        add)       shift; githook_cmd_add "$@" ;;
        uninstall) githook_cmd_uninstall ;;
        check-update) githook_cmd_check_update ;;
        version)   githook_cmd_version ;;
        status)    githook_cmd_status ;;
        help|--help|-h) githook_cmd_help ;;
        *) githook_error "unknown command: $_command (try ./githook.sh help)" ;;
    esac
}

# run if executed directly or piped
case "${0##*/}" in
    githook.sh|githook|sh|bash|dash|ash|zsh|ksh) githook_main "$@" ;;
esac
