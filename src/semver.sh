# version comparison
# returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
githook_version_compare() {
    _v1="${1#v}" _v2="${2#v}"
    [ "$_v1" = "$_v2" ] && return 0

    # parse X.Y.Z
    _m1="${_v1%%.*}" _r1="${_v1#*.}" _n1="${_r1%%.*}" _p1="${_r1#*.}"
    _m2="${_v2%%.*}" _r2="${_v2#*.}" _n2="${_r2%%.*}" _p2="${_r2#*.}"

    # compare numerically
    [ "$_m1" -gt "$_m2" ] 2>/dev/null && return 1
    [ "$_m1" -lt "$_m2" ] 2>/dev/null && return 2
    [ "$_n1" -gt "$_n2" ] 2>/dev/null && return 1
    [ "$_n1" -lt "$_n2" ] 2>/dev/null && return 2
    [ "$_p1" -gt "$_p2" ] 2>/dev/null && return 1
    [ "$_p1" -lt "$_p2" ] 2>/dev/null && return 2
    return 0
}
