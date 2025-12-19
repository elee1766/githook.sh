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

if package.json exists, a "prepare" script is added automatically.

## manual setup

```sh
curl -fsS https://githook.sh -o githook.sh
chmod +x githook.sh
./githook.sh install
```

## commands

```
./githook.sh install              set up git hooks (run once per user)
./githook.sh uninstall            remove git hooks configuration
./githook.sh check-update         check for updates
```

## adding hooks

create executable scripts in `.githook/` (e.g. `.githook/pre-commit`)

## makefile integration

```makefile
.PHONY: init
init:
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
