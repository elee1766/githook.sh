#!/bin/sh
# githook.sh
#
# a single-file, zero-dependency git hooks manager.
#
# LICENSE: Unlicense
# SITE: https://githook.sh
# SOURCE: https://github.com/elee1766/githook.sh

set -e
# constants

GITHOOK_VERSION="0.1.5"
GITHOOK_API_URL="https://githook.sh"
GITHOOK_HOOKS_DIR=".githook"

GITHOOK_SUPPORTED_HOOKS="applypatch-msg pre-applypatch post-applypatch pre-commit \
prepare-commit-msg commit-msg post-commit pre-rebase post-checkout \
post-merge pre-push post-rewrite pre-auto-gc"
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
# http utilities

githook_download_file() {
    _url="$1"
    _output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$_url" -o "$_output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$_url" -O "$_output"
    else
        githook_error "curl or wget required"
    fi
}
# commands

githook_cmd_init() {
    _git_root="$(githook_check_git_repository)"
    _target_path="$_git_root/githook.sh"

    # check if running from file or piped
    case "${0##*/}" in
        sh|bash|dash|ash|zsh|ksh) _piped=1 ;;
        *) _piped=0 ;;
    esac

    if [ "$_piped" -eq 0 ]; then
        _script_path="$(githook_get_script_path)"
        if [ "$_script_path" = "$_target_path" ]; then
            githook_info "already in repo root: $_target_path"
            chmod +x "$_target_path"
            return
        fi
    fi

    if [ -f "$_target_path" ]; then
        githook_warn "githook.sh already exists in repo root"
        printf "overwrite? [y/N] "
        read -r _response
        case "$_response" in
            [yY]|[yY][eE][sS]) ;;
            *) githook_info "cancelled"; return ;;
        esac
    fi

    if [ "$_piped" -eq 1 ]; then
        githook_info "downloading githook.sh..."
        githook_download_file "$GITHOOK_API_URL" "$_target_path"
    else
        cp "$_script_path" "$_target_path"
    fi
    chmod +x "$_target_path"

    githook_info "installed to $_target_path"
    echo ""

    # run install
    githook_cmd_install

    # try to add npm prepare script if package.json exists
    if [ -f "$_git_root/package.json" ]; then
        echo ""
        if command -v npm >/dev/null 2>&1; then
            if npm pkg set scripts.prepare="./githook.sh install" 2>/dev/null; then
                githook_info "added prepare script to package.json"
            else
                githook_info "tip: add to package.json scripts: \"prepare\": \"./githook.sh install\""
            fi
        else
            githook_info "tip: add to package.json scripts: \"prepare\": \"./githook.sh install\""
        fi
    else
        echo ""
        githook_info "note: each user must run ./githook.sh install after cloning"
    fi
}

githook_cmd_install() {
    if githook_is_disabled; then
        githook_debug "skipping install (GITHOOK_DISABLE is set)"
        exit 0
    fi

    _git_root="$(githook_check_git_repository)"
    _hooks_dir="$_git_root/$GITHOOK_HOOKS_DIR"

    githook_info "installing git hooks..."

    _existing_hooks_path="$(git config core.hooksPath 2>/dev/null || echo "")"
    if [ -n "$_existing_hooks_path" ] && [ "$_existing_hooks_path" != "$GITHOOK_HOOKS_DIR" ]; then
        githook_warn "core.hooksPath already set to: $_existing_hooks_path"
        printf "override with $GITHOOK_HOOKS_DIR? [y/N] "
        read -r _response
        case "$_response" in
            [yY]|[yY][eE][sS]) ;;
            *) githook_error "cancelled" ;;
        esac
    fi

    [ ! -d "$_hooks_dir" ] && mkdir -p "$_hooks_dir"

    git config core.hooksPath "$GITHOOK_HOOKS_DIR"
    githook_info "set core.hooksPath=$GITHOOK_HOOKS_DIR"
}

githook_cmd_uninstall() {
    _git_root="$(githook_check_git_repository)"
    _hooks_dir="$_git_root/$GITHOOK_HOOKS_DIR"

    githook_info "uninstalling..."

    git config --unset core.hooksPath 2>/dev/null || true
    githook_info "removed core.hooksPath"

    [ -d "$_hooks_dir" ] && githook_info "kept $GITHOOK_HOOKS_DIR/ (your scripts are still there)"

    echo ""
    githook_info "done. reinstall with: ./githook.sh install"
}

githook_cmd_check() {
    githook_info "checking for updates..."

    _current_version="$GITHOOK_VERSION"
    githook_info "current: $_current_version"

    if ! _remote_script="$(githook_download_file "$GITHOOK_API_URL" - 2>/dev/null)"; then
        githook_error "failed to fetch latest version"
    fi

    _latest_version="$(echo "$_remote_script" | grep '^GITHOOK_VERSION=' | cut -d'"' -f2)"

    [ -z "$_latest_version" ] && githook_error "could not parse remote version"

    githook_info "latest: $_latest_version"

    githook_version_compare "$_current_version" "$_latest_version"
    _result=$?

    if [ $_result -eq 0 ]; then
        githook_info "already up to date"
        exit 0
    elif [ $_result -eq 1 ]; then
        githook_info "you're ahead of latest release"
        exit 0
    fi

    echo ""
    githook_info "update available: $_current_version -> $_latest_version"
    echo ""
    githook_info "to update, run: ./githook.sh update"
}

githook_cmd_update() {
    _git_root="$(githook_check_git_repository)"
    _script_path="$_git_root/githook.sh"

    if [ ! -f "$_script_path" ]; then
        githook_error "githook.sh not found in repo root"
    fi

    githook_info "updating githook.sh..."

    if ! githook_download_file "$GITHOOK_API_URL" "$_script_path"; then
        githook_error "failed to download update"
    fi

    chmod +x "$_script_path"
    githook_info "updated successfully"
}

githook_cmd_version() {
    echo "githook.sh $GITHOOK_VERSION"
}

githook_cmd_help() {
    _help='# githook.sh

a single-file, zero-dependency git hooks manager.

## quick install

```sh
curl -fsS https://githook.sh | sh
```

or with wget:

```sh
wget -qO- https://githook.sh | sh
```

## manual setup

```sh
curl -fsS https://githook.sh -o githook.sh
chmod +x githook.sh
./githook.sh install
```

## commands

```
./githook.sh install       set up git hooks (run once per clone)
./githook.sh uninstall     remove git hooks configuration
./githook.sh check         check for updates
./githook.sh update        download latest version
```

## adding hooks

create executable scripts in .githook/ (e.g. .githook/pre-commit)

## npm/pnpm/bun integration

```json
"prepare": "./githook.sh install"
```

## makefile integration

```makefile
.PHONY: prepare
prepare:
	./githook.sh install
```

## environment variables

```
GITHOOK_DISABLE=1    skip hooks/installation (useful for ci)
GITHOOK_DEBUG=1      show debug output
```

## supported hooks

```
pre-commit, pre-push, commit-msg, prepare-commit-msg,
post-commit, post-merge, pre-rebase, post-checkout,
post-rewrite, pre-auto-gc, applypatch-msg,
pre-applypatch, post-applypatch
```

## source

https://github.com/elee1766/githook.sh

## license

unlicense (public domain)'

    if command -v glow >/dev/null 2>&1; then
        echo "$_help" | glow -s dark -
    else
        echo "$_help"
    fi
}
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
        uninstall) githook_cmd_uninstall ;;
        check)     githook_cmd_check ;;
        update)    githook_cmd_update ;;
        version)   githook_cmd_version ;;
        help|--help|-h) githook_cmd_help ;;
        *) githook_error "unknown command: $_command (try ./githook.sh help)" ;;
    esac
}

# run if executed directly or piped
case "${0##*/}" in
    githook.sh|githook|sh|bash|dash|ash|zsh|ksh) githook_main "$@" ;;
esac
