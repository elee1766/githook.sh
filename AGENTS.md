# AGENTS.md - coding agent guide for githook.sh

## Project overview

POSIX shell script (~311 lines built) that manages git hooks. The built script is
a concatenation of `src/*.sh` files. No external dependencies beyond POSIX `sh`,
`git`, and optionally `curl`/`wget`. Dual-licensed under Unlicense and MIT.

## Build commands

```sh
make build        # concatenate src/*.sh into .githook.sh (default target)
make site         # process m4 templates into site/dist/
make clean        # remove built artifacts
```

## Test commands

```sh
make test         # build + run unit tests
make test-hooks   # build + run integration tests (creates temp git repos)
make test-all     # both unit and integration tests
```

### Running a single test

Unit tests cannot be run individually (they depend on the runner sourcing src/
files and defining assert functions). Edit `test/run.sh` temporarily to source
only the desired file, or run the full suite.

Integration tests are self-contained and can be run individually:
```sh
sh test/hooks/1_default.sh
sh test/hooks/2_skip_hooks.sh
```

### Writing tests

Unit tests (`test/test_*.sh`): assertions run at top level when sourced by the
runner. No function wrapping. Use `assert_eq`, `assert_true`, `assert_false`.

```sh
echo "section name:"
githook_version_compare "1.0.0" "1.0.0"; assert_eq "$?" "0" "1.0.0 = 1.0.0"
```

Integration tests (`test/hooks/[0-9]_*.sh`): source `functions.sh`, call `setup`,
`install`, test with `expect <exit_code> <command>`, end with `ok`.

## File locations

```
src/
  header.sh      - shebang, license, set -e
  constants.sh   - version, api url, hooks dir, supported hooks
  utils.sh       - logging, validation, git helpers, semver, download
  commands.sh    - all command implementations + help text
  main.sh        - entry point and command dispatch
  footer.sh      - trailing comment
  (header.sh contains the license line: "LICENSE: Unlicense OR MIT")

site/
  Caddyfile      - web server config (content negotiation)
  src/
    _base.m4     - m4 macro definitions for HTML templates
    index.m4     - homepage template
    docs/index.m4 - docs page template
    llms.txt     - llm-friendly plain-text documentation
    style.css    - site styles
    copy.js      - copy-to-clipboard script
    (index.m4 and llms.txt both mention the dual Unlicense/MIT license)

test/
  run.sh         - unit test runner
  test_*.sh      - unit test files
  hooks/
    run.sh       - integration test runner
    functions.sh - test helpers (setup, install, expect, ok, error)
    [0-9]_*.sh   - integration test scripts
```

## Files to update when changing commands/features

- `src/main.sh` - command dispatch (case statement)
- `src/commands.sh` - command implementations and help text
- `README.md` - project readme
- `site/src/index.m4` - website homepage
- `site/src/llms.txt` - llm documentation
- `test/test_*.sh` - if command behavior changes

## Code style

### Shell dialect

POSIX `sh` only. No bashisms. Shebang is `#!/bin/sh`. The script must run on
any POSIX-compliant shell (dash, ash, busybox sh, etc.).

### Naming conventions

- **Functions:** `githook_` prefix. Commands: `githook_cmd_<name>`.
  Utilities: `githook_<verb>` (e.g. `githook_error`, `githook_is_valid_hook`).
- **Constants:** `GITHOOK_` prefix, `UPPER_SNAKE_CASE`
  (e.g. `GITHOOK_VERSION`, `GITHOOK_SUPPORTED_HOOKS`).
- **Local variables:** underscore-prefixed `_lower_snake_case`
  (e.g. `_git_root`, `_target_path`). This is the POSIX way to indicate
  function-local scope since `local` is not POSIX.
- **Test globals:** plain `UPPER_SNAKE_CASE` (`PASSED`, `FAILED`).

### Formatting

- Indent with tabs? No — **2-space indentation** throughout.
- One-liner functions for simple utilities:
  ```sh
  githook_error() { echo "error: $1" >&2; exit 1; }
  githook_warn() { echo "warning: $1" >&2; }
  ```
- Prefer `&&`/`||` chaining for simple single-line conditionals:
  ```sh
  [ "$_existing" = "$GITHOOK_INTERNAL_DIR" ] && return
  githook_is_disabled && exit 0
  ```
- Use `if/then/fi` only when the body has multiple statements.
- `case` statements for pattern matching. Inline for simple cases:
  ```sh
  case "$1" in 1|true|yes|on) return 0 ;; *) return 1 ;; esac
  ```
- Comments: terse, lowercase, no trailing period. Section headers as comments.
- Functions separated by blank lines.
- No trailing semicolons on standalone statements.

### Quoting

Always quote variable expansions. No exceptions.

```sh
"$_git_root"          # simple variable
"${1:-}"              # positional with default
"${GITHOOK:-}"        # env var with default
"${0##*/}"            # parameter expansion (basename)
"${1#v}"              # strip prefix
```

### Error handling

- `set -e` is active at the top level. Any unhandled nonzero exit aborts.
- `githook_error "message"` prints to stderr and exits 1.
- `githook_warn "message"` prints to stderr, does not exit.
- Guard commands that may fail with `|| true`:
  ```sh
  git config --unset core.hooksPath 2>/dev/null || true
  _existing="$(git config core.hooksPath 2>/dev/null || true)"
  ```
- Capture nonzero return codes without triggering `set -e`:
  ```sh
  _cmp=0; githook_version_compare "$GITHOOK_VERSION" "$_latest" || _cmp=$?
  ```

### Output conventions

- Errors to stderr: `>&2`
- Suppress unwanted output: `>/dev/null 2>&1`
- User-facing messages via `githook_info`, `githook_warn`, `githook_error`.

## Architecture notes

- Build is plain `cat` concatenation of src/ files in fixed order. Each src/
  file must be self-contained (no duplicate definitions, no conflicts).
- The hook runner (`.githook/_/h`) determines which hook was called via
  `basename "$0"`. Hook wrappers in `_/` are identical 2-line scripts that
  source `h`.
- Content negotiation (browser vs curl) is handled by Caddy, not the script.
- `curl ... | sh` detects piped execution and runs `init` by default.
- `init` auto-detects `package.json` and adds a `prepare` script.
- Husky migration is available via `init` (auto) or `migrate husky` (manual).

## CI

- `.github/workflows/ci.yml` runs `make build && make test` on push/PR to main.
- `GITHOOK=0` is set in CI to skip hooks during checkout.
- Integration tests (`test-hooks`) are not run in CI.
- `.github/workflows/release.yml` handles tag-triggered releases and fly.io deploy.
