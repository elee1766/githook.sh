# utility functions

githook_error() { echo "error: $1" >&2; exit 1; }
githook_warn() { echo "warning: $1" >&2; }
githook_info() { echo "$1"; }
githook_debug() { githook_is_debug_enabled && echo "debug: $1" >&2 || true; }

githook_is_truthy() {
    case "$1" in 1|true|True|TRUE|yes|Yes|YES|on|On|ON) return 0 ;; *) return 1 ;; esac
}
githook_is_debug_enabled() { githook_is_truthy "${GITHOOK_DEBUG:-}"; }
githook_is_disabled() { githook_is_truthy "${GITHOOK_DISABLE:-}"; }

githook_is_valid_hook() {
    case " $GITHOOK_SUPPORTED_HOOKS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}
