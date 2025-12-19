# utility functions

githook_error() { echo "error: $1" >&2; exit 1; }
githook_warn() { echo "warning: $1" >&2; }
githook_info() { echo "$1"; }
githook_debug() { githook_is_debug_enabled && echo "debug: $1" >&2 || true; }

githook_is_truthy() {
    case "$1" in 1|true|True|TRUE|yes|Yes|YES|on|On|ON) return 0 ;; *) return 1 ;; esac
}
githook_is_debug_enabled() { githook_is_truthy "${GITHOOK_DEBUG:-}"; }
githook_is_disabled() { [ "${GITHOOK:-}" = "0" ]; }

githook_is_valid_hook() {
    case " $GITHOOK_SUPPORTED_HOOKS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}
# git helpers

githook_check_git_repository() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        githook_error "not a git repository"
    fi
    git rev-parse --show-toplevel
}
# version comparison (returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2)
githook_version_compare() {
    _v1="${1#v}" _v2="${2#v}"
    [ "$_v1" = "$_v2" ] && return 0
    _m1="${_v1%%.*}" _r1="${_v1#*.}" _n1="${_r1%%.*}" _p1="${_r1#*.}"
    _m2="${_v2%%.*}" _r2="${_v2#*.}" _n2="${_r2%%.*}" _p2="${_r2#*.}"
    [ "$_m1" -gt "$_m2" ] 2>/dev/null && return 1
    [ "$_m1" -lt "$_m2" ] 2>/dev/null && return 2
    [ "$_n1" -gt "$_n2" ] 2>/dev/null && return 1
    [ "$_n1" -lt "$_n2" ] 2>/dev/null && return 2
    [ "$_p1" -gt "$_p2" ] 2>/dev/null && return 1
    [ "$_p1" -lt "$_p2" ] 2>/dev/null && return 2
    return 0
}
# file downloader with fallback from curl to wget
githook_download_file() {
    _url="$1" _output="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$_url" -o "$_output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$_url" -O "$_output"
    else
        githook_error "curl or wget required"
    fi
}
