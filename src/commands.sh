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
        githook_warn ".githook.sh already exists in repo root"
        printf "overwrite? [y/N] " && read -r _response
        case "$_response" in [yY]|[yY][eE][sS]) ;; *) githook_info "cancelled"; return ;; esac
    fi

    if [ "$_piped" -eq 1 ]; then
        githook_info "downloading .githook.sh..."
        githook_download_file "$GITHOOK_API_URL" "$_target_path"
    else
        cp "$_script_path" "$_target_path"
    fi
    chmod +x "$_target_path"
    githook_info "installed to $_target_path"

    githook_cmd_install
    echo ""
    if [ -f "$_git_root/package.json" ]; then
        npm pkg set scripts.prepare="./.githook.sh install" 2>/dev/null \
            && githook_info "added prepare script to package.json" \
            || githook_info "tip: add to package.json scripts: \"prepare\": \"./.githook.sh install\""
    else
        githook_info "note: each user must run ./.githook.sh install after cloning"
    fi
}

githook_cmd_install() {
    githook_is_disabled && githook_debug "skipping install (GITHOOK=0)" && exit 0
    _git_root="$(githook_check_git_repository)"
    githook_info "installing git hooks..."

    _existing="$(git config core.hooksPath 2>/dev/null || true)"
    if [ -n "$_existing" ] && [ "$_existing" != "$GITHOOK_INTERNAL_DIR" ] && [ "$_existing" != "$GITHOOK_DIR" ]; then
        githook_warn "core.hooksPath already set to: $_existing"
        printf "override with $GITHOOK_INTERNAL_DIR? [y/N] " && read -r _response
        case "$_response" in [yY]|[yY][eE][sS]) ;; *) githook_error "cancelled" ;; esac
    fi

    # create directories
    [ ! -d "$_git_root/$GITHOOK_DIR" ] && mkdir -p "$_git_root/$GITHOOK_DIR"
    mkdir -p "$_git_root/$GITHOOK_INTERNAL_DIR"

    # create .gitignore to exclude _/ from version control
    echo "*" > "$_git_root/$GITHOOK_INTERNAL_DIR/.gitignore"

    # create shared hook runner
    cat > "$_git_root/$GITHOOK_INTERNAL_DIR/h" << 'HOOK'
#!/bin/sh
[ "$GITHOOK" = "2" ] && set -x
[ "$GITHOOK" = "0" ] && exit 0
[ -f ~/.config/githook/init.sh ] && . ~/.config/githook/init.sh
n=$(basename "$0")
h=$(dirname "$(dirname "$0")")/$n
[ ! -f "$h" ] && exit 0
sh -e "$h" "$@"
c=$?
[ $c != 0 ] && echo "githook - $n failed (code $c)"
[ $c = 127 ] && echo "githook - command not found in PATH=$PATH"
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

githook_cmd_uninstall() {
    _git_root="$(githook_check_git_repository)"
    githook_info "uninstalling..."
    git config --unset core.hooksPath 2>/dev/null || true
    githook_info "removed core.hooksPath"
    # remove internal wrapper directory
    [ -d "$_git_root/$GITHOOK_INTERNAL_DIR" ] && rm -rf "$_git_root/$GITHOOK_INTERNAL_DIR" && githook_info "removed $GITHOOK_INTERNAL_DIR/"
    [ -d "$_git_root/$GITHOOK_DIR" ] && githook_info "kept $GITHOOK_DIR/ (your scripts are still there)"
    githook_info "reinstall with: ./.githook.sh install"
}

githook_cmd_check() {
    githook_info "checking for updates..."
    githook_info "current: $GITHOOK_VERSION"
    _remote="$(githook_download_file "$GITHOOK_API_URL" - 2>/dev/null)" || githook_error "failed to fetch latest version"
    _latest="$(echo "$_remote" | grep '^GITHOOK_VERSION=' | cut -d'"' -f2)"
    case "$_latest" in [0-9]*.[0-9]*.[0-9]*) ;; *) githook_error "invalid remote version: $_latest" ;; esac
    githook_info "latest: $_latest"
    githook_version_compare "$GITHOOK_VERSION" "$_latest"
    case $? in 0) githook_info "up to date" ;; 1) githook_info "ahead of latest" ;; 2) githook_info "update available! run: ./.githook.sh update" ;; esac
}

githook_cmd_update() {
    _git_root="$(githook_check_git_repository)"
    _path="$_git_root/.githook.sh"
    [ ! -f "$_path" ] && githook_error ".githook.sh not found in repo root"
    githook_info "updating .githook.sh..."
    githook_download_file "$GITHOOK_API_URL" "$_path" || githook_error "failed to download update"
    chmod +x "$_path"
    githook_info "updated successfully"
}

githook_cmd_version() {
    echo "githook.sh $GITHOOK_VERSION"
}

githook_cmd_help() { _h='# .githook.sh - a single-file, zero-dependency git hooks manager.

## quick install
  curl -sSL https://githook.sh | sh
  wget -qO- https://githook.sh | sh

## manual setup
  curl -sSL https://githook.sh -o .githook.sh
  chmod +x .githook.sh && ./.githook.sh install

## commands
  install       set up git hooks (run once per clone)
  uninstall     remove git hooks configuration
  check         check for updates
  update        download latest version

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
