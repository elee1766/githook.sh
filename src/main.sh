# main entry point

githook_main() {
    _command="${1:-help}"

    case "$_command" in
        setup)     githook_cmd_setup ;;
        install)   githook_cmd_install ;;
        add)       shift; githook_cmd_add "$@" ;;
        uninstall) githook_cmd_uninstall ;;
        update)    githook_cmd_update ;;
        version)   githook_cmd_version ;;
        status)    githook_cmd_status ;;
        help|--help|-h) githook_cmd_help ;;
        *) githook_error "unknown command: $_command (try ./githook.sh help)" ;;
    esac
}

# only run if executed directly (not sourced)
case "${0##*/}" in
    githook.sh|githook) githook_main "$@" ;;
esac
