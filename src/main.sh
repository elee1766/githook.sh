# main entry point

githook_main() {
    # detect if running via pipe (curl | sh)
    case "${0##*/}" in sh|bash|dash|ash|zsh|ksh) _piped=1 ;; *) _piped=0 ;; esac

    # default: piped always runs init, otherwise help if installed
    if [ -z "${1:-}" ]; then
        if [ "$_piped" -eq 1 ]; then
            _command="init"
        else
            _command="help"
        fi
    else
        _command="$1"
    fi

    case "$_command" in
        init)      githook_cmd_init ;;
        install)   githook_cmd_install ;;
        uninstall) githook_cmd_uninstall ;;
        migrate)   case "${2:-}" in husky) githook_cmd_migrate_husky ;; *) githook_error "usage: ./.githook.sh migrate husky" ;; esac ;;
        check)     githook_cmd_check ;;
        update)    githook_cmd_update ;;
        version)   githook_cmd_version ;;
        help|--help|-h) githook_cmd_help ;;
        *) githook_error "unknown command: $_command (try ./.githook.sh help)" ;;
    esac
}

# run if executed directly or piped
case "${0##*/}" in
    .githook.sh|githook.sh|githook|sh|bash|dash|ash|zsh|ksh) githook_main "$@" ;;
esac
