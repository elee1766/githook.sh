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

githook_cmd_add() {
    _hook_name="$1"
    _command="$2"

    if [ -z "$_hook_name" ]; then
        githook_error "hook name required. example: ./githook.sh add pre-commit \"npm test\""
    fi

    if ! githook_is_valid_hook "$_hook_name"; then
        githook_error "invalid hook: $_hook_name"
    fi

    _git_root="$(githook_check_git_repository)"
    _hooks_dir="$_git_root/$GITHOOK_HOOKS_DIR"
    _hook_file="$_hooks_dir/$_hook_name"

    [ ! -d "$_hooks_dir" ] && mkdir -p "$_hooks_dir"

    if [ -f "$_hook_file" ]; then
        if [ -n "$_command" ]; then
            echo "$_command" >> "$_hook_file"
            githook_info "appended to $GITHOOK_HOOKS_DIR/$_hook_name"
        else
            githook_info "hook exists: $GITHOOK_HOOKS_DIR/$_hook_name"
        fi
    else
        {
            echo "#!/bin/sh"
            [ -n "$_command" ] && echo "$_command"
        } > "$_hook_file"
        chmod +x "$_hook_file"
        githook_info "created $GITHOOK_HOOKS_DIR/$_hook_name"
    fi

    [ -z "$_command" ] && githook_info "edit: $_hook_file"
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

githook_cmd_check_update() {
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
    githook_info "to update, run:"
    echo "  curl -fsS $GITHOOK_API_URL -o githook.sh"
}

githook_cmd_version() {
    echo "githook.sh $GITHOOK_VERSION"
}

githook_cmd_status() {
    _git_root="$(githook_check_git_repository)"
    _hooks_dir="$_git_root/$GITHOOK_HOOKS_DIR"
    _hooks_path="$(git config core.hooksPath 2>/dev/null || echo "(not set)")"

    echo "version: $GITHOOK_VERSION"
    echo "hooks path: $_hooks_path"
    echo "hooks dir: $_hooks_dir"
    echo ""

    if [ "$_hooks_path" = "$GITHOOK_HOOKS_DIR" ]; then
        echo "status: installed"
    else
        echo "status: not installed (run ./githook.sh install)"
    fi

    echo ""
    echo "hooks:"

    _found_hooks=0
    for _hook in $GITHOOK_SUPPORTED_HOOKS; do
        _user_script="$_hooks_dir/$_hook"
        if [ -f "$_user_script" ]; then
            if [ -x "$_user_script" ]; then
                echo "  $_hook"
            else
                echo "  $_hook (not executable)"
            fi
            _found_hooks=1
        fi
    done

    [ $_found_hooks -eq 0 ] && echo "  (none)"
}

githook_cmd_help() {
    cat <<EOF
githook.sh - git hooks manager

usage: ./githook.sh <command> [arguments]

commands:
  init                  initialize githook.sh in repo
  install               set up git hooks (run once per user)
  add <hook> [command]  create or append to a hook
  status                show status
  uninstall             remove git hooks config
  check-update          check for updates
  version               show version
  help                  show this

quick start:
  ./githook.sh install
  ./githook.sh add pre-commit "npm test"

environment:
  GITHOOK_DISABLE=1    skip hooks/install (for ci)
  GITHOOK_DEBUG=1      debug output

npm (package.json):
  {
    "scripts": {
      "prepare": "./githook.sh install"
    }
  }

hooks:
  pre-commit, pre-push, commit-msg, prepare-commit-msg,
  post-commit, post-merge, pre-rebase, post-checkout,
  post-rewrite, pre-auto-gc, applypatch-msg, pre-applypatch,
  post-applypatch

https://githook.sh
EOF
}
