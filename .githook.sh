#!/bin/sh
# githook.sh
#
# git hooks made easier.
#
# LICENSE: Unlicense OR MIT
# SITE: https://githook.sh
# SOURCE: https://github.com/elee1766/githook.sh

set -e
# constants

GITHOOK_VERSION="0.1.20"
GITHOOK_API_URL="https://githook.sh"
GITHOOK_DIR=".githook"
GITHOOK_INTERNAL_DIR=".githook/_"

GITHOOK_SUPPORTED_HOOKS="applypatch-msg pre-applypatch post-applypatch pre-commit \
prepare-commit-msg commit-msg post-commit pre-rebase post-checkout \
post-merge pre-push post-rewrite pre-auto-gc"
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
# commands

githook_cmd_init() {
    _git_root="$(githook_check_git_repository)"
    _target_path="$_git_root/.githook.sh"
    case "${0##*/}" in sh|bash|dash|ash|zsh|ksh) _piped=1 ;; *) _piped=0 ;; esac

    if [ "$_piped" -eq 0 ]; then
        _script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
        [ "$_script_path" = "$_target_path" ] && githook_info "already in repo root" && chmod +x "$_target_path" && return
    fi

    if [ -f "$_target_path" ]; then
        githook_info ".githook.sh already exists, running install..."
        "$_target_path" install
        return
    fi

    if [ "$_piped" -eq 1 ]; then
        githook_info "downloading .githook.sh..."
        githook_download_file "$GITHOOK_API_URL" "$_target_path"
    else
        cp "$_script_path" "$_target_path"
    fi
    chmod +x "$_target_path"
    githook_info "installed to $_target_path"

    # auto-migrate from husky if detected
    if [ -d "$_git_root/.husky" ]; then
        githook_cmd_migrate_husky
    fi

    githook_cmd_install
    echo ""
    if [ -f "$_git_root/package.json" ]; then
        npm pkg set scripts.prepare="./.githook.sh install" 2>/dev/null \
            && githook_info "added prepare script to package.json" \
            || githook_info "tip: add to package.json scripts: \"prepare\": \"./.githook.sh install\""
    else
        githook_info "note: each user must run install after cloning:"
        echo "  ./.githook.sh install"
    fi
}

githook_cmd_install() {
    githook_is_disabled && githook_debug "skipping install (GITHOOK=0)" && exit 0
    _git_root="$(githook_check_git_repository)"

    _existing="$(git config core.hooksPath 2>/dev/null || true)"

    # already configured correctly - exit silently
    [ "$_existing" = "$GITHOOK_INTERNAL_DIR" ] && return

    # different hooks path set - prompt to override
    if [ -n "$_existing" ] && [ "$_existing" != "$GITHOOK_DIR" ]; then
        githook_warn "core.hooksPath already set to: $_existing"
        printf "override with $GITHOOK_INTERNAL_DIR? [y/N] " && read -r _response
        case "$_response" in [yY]|[yY][eE][sS]) ;; *) githook_error "cancelled" ;; esac
    fi

    githook_info "installing git hooks..."

    # create directories
    [ ! -d "$_git_root/$GITHOOK_DIR" ] && mkdir -p "$_git_root/$GITHOOK_DIR"
    mkdir -p "$_git_root/$GITHOOK_INTERNAL_DIR"

    # create .gitignore to exclude _/ from version control
    echo "*" > "$_git_root/$GITHOOK_INTERNAL_DIR/.gitignore"

    # create shared hook runner
    cat > "$_git_root/$GITHOOK_INTERNAL_DIR/h" << 'HOOK'
#!/bin/sh
[ "$GITHOOK" = "2" ] && set -x
n=$(basename "$0")
h=$(dirname "$(dirname "$0")")/$n
[ ! -f "$h" ] && exit 0
[ -f "$HOME/.config/githook/init.sh" ] && . "$HOME/.config/githook/init.sh"
[ "$GITHOOK" = "0" ] && exit 0
export PATH="node_modules/.bin:$PATH"
"$h" "$@"
c=$?
[ $c != 0 ] && echo "githook - $n failed (code $c)"
[ $c = 127 ] && echo "githook - command not found"
exit $c
HOOK

    # create wrapper for each supported hook
    for _hook in $GITHOOK_SUPPORTED_HOOKS; do
        echo '#!/bin/sh
. "$(dirname "$0")/h"' > "$_git_root/$GITHOOK_INTERNAL_DIR/$_hook"
        chmod +x "$_git_root/$GITHOOK_INTERNAL_DIR/$_hook"
    done

    git config core.hooksPath "$GITHOOK_INTERNAL_DIR"
    githook_info "set core.hooksPath=$GITHOOK_INTERNAL_DIR"
}

githook_cmd_migrate_husky() {
    _git_root="$(githook_check_git_repository)"
    _husky_dir="$_git_root/.husky"
    [ ! -d "$_husky_dir" ] && githook_error ".husky directory not found"

    githook_info "migrating hooks from husky..."
    [ ! -d "$_git_root/$GITHOOK_DIR" ] && mkdir -p "$_git_root/$GITHOOK_DIR"

    _migrated=0
    for _hook in $GITHOOK_SUPPORTED_HOOKS; do
        if [ -f "$_husky_dir/$_hook" ]; then
            cp "$_husky_dir/$_hook" "$_git_root/$GITHOOK_DIR/$_hook"
            chmod +x "$_git_root/$GITHOOK_DIR/$_hook"
            githook_info "  migrated $_hook"
            _migrated=$((_migrated + 1))
        fi
    done

    if [ $_migrated -eq 0 ]; then
        githook_info "no hooks found to migrate"
    else
        githook_info "migrated $_migrated hook(s)"
        githook_info "after verifying, remove husky:"
        echo "  rm -rf .husky"
    fi
}

githook_cmd_uninstall() {
    _git_root="$(githook_check_git_repository)"
    githook_info "uninstalling..."
    git config --unset core.hooksPath 2>/dev/null || true
    githook_info "removed core.hooksPath"
    # remove internal wrapper directory
    [ -d "$_git_root/$GITHOOK_INTERNAL_DIR" ] && rm -rf "$_git_root/$GITHOOK_INTERNAL_DIR" && githook_info "removed $GITHOOK_INTERNAL_DIR/"
    [ -d "$_git_root/$GITHOOK_DIR" ] && githook_info "kept $GITHOOK_DIR/ (your scripts are still there)"
    githook_info "to reinstall:"
    echo "  ./.githook.sh install"
}

githook_cmd_check() {
    _remote="$(githook_download_file "$GITHOOK_API_URL" - 2>/dev/null)" || githook_error "failed to fetch latest version"
    _latest="$(echo "$_remote" | grep '^GITHOOK_VERSION=' | cut -d'"' -f2)"
    case "$_latest" in [0-9]*.[0-9]*.[0-9]*) ;; *) githook_error "invalid remote version: $_latest" ;; esac
    _cmp=0; githook_version_compare "$GITHOOK_VERSION" "$_latest" || _cmp=$?
    case $_cmp in
        0|1) githook_info "up to date ($GITHOOK_VERSION)" ;;
        2) githook_info "$GITHOOK_VERSION -> $_latest"
           echo "  ./.githook.sh update" ;;
    esac
}

githook_cmd_update() {
    _git_root="$(githook_check_git_repository)"
    _path="$_git_root/.githook.sh"
    [ ! -f "$_path" ] && githook_error ".githook.sh not found in repo root"
    _remote="$(githook_download_file "$GITHOOK_API_URL" - 2>/dev/null)" || githook_error "failed to fetch latest version"
    _latest="$(echo "$_remote" | grep '^GITHOOK_VERSION=' | cut -d'"' -f2)"
    case "$_latest" in [0-9]*.[0-9]*.[0-9]*) ;; *) githook_error "invalid remote version: $_latest" ;; esac
    _cmp=0; githook_version_compare "$GITHOOK_VERSION" "$_latest" || _cmp=$?
    case $_cmp in 0|1) githook_info "already up to date ($GITHOOK_VERSION)"; return ;; esac
    githook_info "updating $GITHOOK_VERSION -> $_latest..."
    echo "$_remote" > "$_path"
    chmod +x "$_path"
    githook_info "run install to update hooks:"
    echo "  ./.githook.sh install"
    exit 0
}

githook_cmd_version() {
    echo "githook.sh $GITHOOK_VERSION"
}

githook_cmd_help() { _h='# .githook.sh - git hooks made easier.

## quick setup
  curl -sSL https://githook.sh | sh
  wget -qO- https://githook.sh | sh

## manual setup
  curl -sSL https://githook.sh -o .githook.sh
  chmod +x .githook.sh && ./.githook.sh install

## commands
  install        configure git hooks (run once per clone)
  uninstall      remove git hooks configuration
  migrate husky  migrate hooks from husky
  check          check for updates
  update         download latest version

## adding hooks
  create executable scripts in .githook/ (e.g. .githook/pre-commit)

## npm/pnpm/bun
  npm pkg set scripts.prepare="./.githook.sh install"

## makefile
  .PHONY: prepare
  prepare: ; ./.githook.sh install

## environment variables
  GITHOOK=0        skip hooks (useful for ci)
  GITHOOK_DEBUG=1  show debug output

## more info
  https://githook.sh/docs

## source & license
  https://github.com/elee1766/githook.sh (unlicense)'
if command -v glow >/dev/null 2>&1; then echo "$_h"|glow -s dark -; else echo "$_h"; fi; }
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
# to install:
# curl -sSL https://githook.sh | sh  ->  .githook.sh
