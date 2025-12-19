# claude.md - guide for future updates

## files to update when changing commands/features

when renaming commands, adding features, or changing behavior, update these files:

### source files
- `src/main.sh` - command dispatch (case statement)
- `src/commands.sh` - command implementations and help text

### documentation
- `README.md` - project readme
- `site/index.html` - website html
- `site/llms.txt` - llm-friendly documentation

### tests
- `test/test_*.sh` - if command behavior changes

## file locations

```
src/
  header.sh      - shebang and script header
  constants.sh   - version, api url, hooks dir, supported hooks
  utils.sh       - utility functions (logging, validation)
  git.sh         - git-related functions
  semver.sh      - version parsing and comparison
  http.sh        - download function
  commands.sh    - all command implementations + help text
  main.sh        - entry point and command dispatch

site/
  Caddyfile      - web server config
  index.html     - website (browsers get this)
  llms.txt       - llm documentation

test/
  run.sh         - test runner
  test_*.sh      - test files

.github/workflows/
  ci.yml         - runs tests on push
  release.yml    - version bump, build, deploy on tag push
```

## build process

`make build` concatenates src/*.sh files in order into `githook.sh`

## release process

1. push a tag like `v0.1.3`
2. release.yml updates `src/constants.sh` with new version
3. builds and creates github release
4. deploys to fly.io

## key behaviors

- `curl ... | sh` runs `init` by default (detects piped execution)
- `./githook.sh` with no args runs `help` if already installed, `init` otherwise
- `init` auto-detects package.json and adds prepare script via `npm pkg set`
- browsers (User-Agent contains "Mozilla") get index.html
- everything else gets the raw script
