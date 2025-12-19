# githook.sh

a single-file, zero-dependency git hooks manager.

## quick install

```
curl -fsS https://githook.sh | sh
```

or with wget:

```
wget -qO- https://githook.sh | sh
```

## manual setup

```sh
# download the script
curl -fsS https://githook.sh -o githook.sh
chmod +x githook.sh

# install hooks
./githook.sh install

# add your first hook
./githook.sh add pre-commit "npm test"
```

## commands

```
./githook.sh install              set up git hooks (run once per user)
./githook.sh add <hook> "cmd"     create or append to a hook
./githook.sh status               show installed hooks
./githook.sh check-update         check for updates
./githook.sh uninstall            remove git hooks configuration
```

## npm/package.json integration

```json
{
  "scripts": {
    "prepare": "./githook.sh install"
  }
}
```

## makefile integration

```makefile
.PHONY: setup
setup:
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

## license

unlicense (public domain)
