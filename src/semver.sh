# semver parsing and comparison

# parse semver: sets major, minor, patch, prerelease
# supports: X.Y.Z, X.Y.Z-prerelease
githook_semver() {
    _ver="${1#v}"
    major="" minor="" patch="" prerelease=""

    # reject empty
    [ -z "$_ver" ] && return 1

    # extract prerelease if present
    case "$_ver" in
        *-*)
            prerelease="${_ver#*-}"
            _ver="${_ver%%-*}"
            ;;
    esac

    # must have exactly two dots (X.Y.Z format)
    case "$_ver" in
        *.*.*.* | *..* | .* | *.) return 1 ;;  # too many dots or empty parts
        *.*.*) ;;  # valid format
        *) return 1 ;;  # not enough dots
    esac

    # parse X.Y.Z
    major="${_ver%%.*}"
    _rest="${_ver#*.}"
    minor="${_rest%%.*}"
    patch="${_rest#*.}"

    # all parts must be non-empty
    [ -z "$major" ] || [ -z "$minor" ] || [ -z "$patch" ] && return 1

    # all parts must be numeric (no negatives, no letters)
    case "$major$minor$patch" in
        *[!0-9]*) return 1 ;;
    esac

    return 0
}

# compare two semver strings
# returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
githook_version_compare() {
    _v1="${1#v}"
    _v2="${2#v}"

    [ "$_v1" = "$_v2" ] && return 0

    githook_semver "$_v1" || return 1
    _v1_major="$major" _v1_minor="$minor" _v1_patch="$patch" _v1_pre="$prerelease"

    githook_semver "$_v2" || return 1
    _v2_major="$major" _v2_minor="$minor" _v2_patch="$patch" _v2_pre="$prerelease"

    # compare major.minor.patch
    [ "$_v1_major" -gt "$_v2_major" ] 2>/dev/null && return 1
    [ "$_v1_major" -lt "$_v2_major" ] 2>/dev/null && return 2
    [ "$_v1_minor" -gt "$_v2_minor" ] 2>/dev/null && return 1
    [ "$_v1_minor" -lt "$_v2_minor" ] 2>/dev/null && return 2
    [ "$_v1_patch" -gt "$_v2_patch" ] 2>/dev/null && return 1
    [ "$_v1_patch" -lt "$_v2_patch" ] 2>/dev/null && return 2

    # prerelease has lower precedence than release
    [ -n "$_v1_pre" ] && [ -z "$_v2_pre" ] && return 2
    [ -z "$_v1_pre" ] && [ -n "$_v2_pre" ] && return 1
    [ "$_v1_pre" = "$_v2_pre" ] && return 0

    # compare prerelease lexicographically
    [ "$_v1_pre" \> "$_v2_pre" ] && return 1
    return 2
}
