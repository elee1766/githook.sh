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
