include(`_base.m4')dnl
_HEAD(`githook.sh documentation and guides',`githook.sh - docs')
<h1><a href="/">githook.sh</a> docs</h1>
<nav>
<div>
<b>basics:</b>
<a href="#creating">creating</a> ·
<a href="#examples">examples</a> ·
<a href="#testing">testing</a> ·
<a href="#skipping">skipping</a>
</div>
<div>
<b>integration:</b>
<a href="#ci">ci/cd</a> ·
<a href="#package-json">package.json</a> ·
<a href="#makefile">makefile</a> ·
<a href="#husky">husky</a> ·
<a href="#languages">languages</a>
</div>
<div>
<b>reference:</b>
<a href="#nvm">nvm</a> ·
<a href="#debug">debug</a> ·
<a href="#uninstall">uninstall</a> ·
<a href="#how">how it works</a>
</div>
</nav>

<h2 id="creating">creating a hook</h2>
<p>add an executable script to <code>.githook/</code> named after the git hook you want:</p>
_CODE(`echo '"'"'#!/bin/sh
npm test'"'"' > .githook/pre-commit
chmod +x .githook/pre-commit')
<p>the script must be executable (<code>chmod +x</code>) and start with a shebang (<code>#!/bin/sh</code>).</p>
<p>supported hooks: <code>pre-commit</code>, <code>commit-msg</code>, <code>pre-push</code>, <code>prepare-commit-msg</code>, <code>post-commit</code>, <code>post-merge</code>, <code>pre-rebase</code>, <code>post-checkout</code>, <code>post-rewrite</code>, <code>pre-auto-gc</code>, <code>applypatch-msg</code>, <code>pre-applypatch</code>, <code>post-applypatch</code>.</p>

<h2 id="examples">common hooks</h2>
<p><strong>pre-commit</strong> — runs before commit is created. use for linting, formatting, tests:</p>
_CODE(`#!/bin/sh
npm run lint && npm test')
<p><strong>commit-msg</strong> — validate commit message format. <code>$1</code> is the temp file containing the message:</p>
changequote([,])dnl
_CODE([#!/bin/sh
if ! grep -qE "^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+" "$1"; then
  echo "error: commit message must follow conventional commits format"
  echo "example: feat(auth): add login endpoint"
  exit 1
fi])
changequote(`,')dnl
<p><strong>pre-push</strong> — runs before push. use for full test suite or build verification:</p>
_CODE(`#!/bin/sh
npm run build && npm run test:all')
<p><strong>post-merge</strong> — runs after merge/pull. use to reinstall deps if lockfile changed:</p>
changequote([,])dnl
_CODE([#!/bin/sh
changed_files=$(git diff-tree -r --name-only ORIG_HEAD HEAD)
if echo "$changed_files" | grep -q "package-lock.json"; then
  echo "package-lock.json changed, running npm install..."
  npm install
fi])
changequote(`,')dnl

<h2 id="testing">testing hooks</h2>
<p>run your hook directly without making a commit:</p>
_CODE(`./.githook/pre-commit')
<p>to test that hooks block commits properly, add <code>exit 1</code>:</p>
_CODE(`#!/bin/sh
echo "this will block the commit"
exit 1')
<p>a non-zero exit code aborts the git operation. exit 0 (or no exit) allows it to proceed.</p>

<h2 id="skipping">skipping hooks</h2>
<p>for a single command, use git'"'"'s built-in <code>--no-verify</code> flag:</p>
_CODE(`git commit --no-verify -m "wip"
git push --no-verify')
<p>to disable all hooks for multiple commands:</p>
_CODE(`GITHOOK=0 git commit -m "skip"
GITHOOK=0 git push')
<p>or export it for your session:</p>
_CODE(`export GITHOOK=0
git commit -m "first"
git commit -m "second"
unset GITHOOK')

<h2 id="ci">ci/cd and docker</h2>
<p>hooks are for local development—disable them in CI/CD and containers with <code>GITHOOK=0</code>:</p>
_CODE(`# github actions
env:
  GITHOOK: 0

# gitlab ci
variables:
  GITHOOK: "0"

# docker
ENV GITHOOK=0')

<h2 id="package-json">package.json integration</h2>
<p>auto-install hooks when developers run <code>npm install</code>:</p>
<p><strong>npm / pnpm / bun:</strong></p>
_CODE(`npm pkg set scripts.prepare="./.githook.sh install"')
<p><strong>yarn:</strong></p>
_CODE(`npm pkg set scripts.postinstall="./.githook.sh install"')
<p>yarn uses <code>postinstall</code> instead of <code>prepare</code>.</p>

<h2 id="makefile">makefile integration</h2>
<p>add a target for installing hooks:</p>
_CODE(`.PHONY: prepare
prepare:
	./.githook.sh install')
<p>run after cloning:</p>
_CODE(`make prepare')

<h2 id="husky">migrating from husky</h2>
<p>hooks are automatically migrated during setup if <code>.husky/</code> exists. to migrate manually:</p>
_CODE(`./.githook.sh migrate husky')
<p>this copies hook scripts from <code>.husky/</code> to <code>.githook/</code>. after verifying:</p>
_CODE(`rm -rf .husky
npm uninstall husky')

<h2 id="languages">using other languages</h2>
<p>hooks can be written in any language. use a shell wrapper:</p>
_CODE(`#!/bin/sh
node .githook/pre-commit.js')
<p>or use a shebang directly (the file must still be executable):</p>
_CODE(`#!/usr/bin/env python3
import subprocess
import sys
result = subprocess.run(["pytest", "-x"])
sys.exit(result.returncode)')
_CODE(`#!/usr/bin/env ruby
system("bundle exec rubocop") || exit(1)')

<h2 id="nvm">node version managers</h2>
<p>gui clients and ides may not load your shell profile, causing "command not found" errors. create <code>~/.config/githook/init.sh</code> to fix this globally:</p>
changequote([,])dnl
_CODE([mkdir -p ~/.config/githook
cat > ~/.config/githook/init.sh << 'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF])
changequote(`,')dnl
<p>this is sourced before every hook runs. for fnm use <code>eval "$(fnm env)"</code>, for volta add <code>$VOLTA_HOME/bin</code> to PATH.</p>

<h2 id="debug">debugging</h2>
<p>enable debug output:</p>
_CODE(`GITHOOK_DEBUG=1 git commit -m "test"')
<p>common issues:</p>
<p>• <strong>"command not found"</strong> — see <a href="#nvm">nvm section</a></p>
<p>• <strong>hook not running</strong> — check it'"'"'s executable: <code>ls -la .githook/</code></p>
<p>• <strong>wrong directory</strong> — hooks run from repo root</p>

<h2 id="uninstall">uninstalling</h2>
<p>remove git configuration (keeps your hook scripts):</p>
_CODE(`./.githook.sh uninstall')
<p>to fully remove:</p>
_CODE(`rm -rf .githook .githook.sh')

<h2 id="how">how it works</h2>
<p>githook.sh sets <code>core.hooksPath</code> to <code>.githook/_</code> which contains wrapper scripts. when git runs a hook, the wrapper sources <code>~/.config/githook/init.sh</code>, checks <code>GITHOOK=0</code>, then runs your script from <code>.githook/</code>.</p>
<p>quick setup (<code>curl | sh</code>) runs install if already setup.</p>
<p>each developer runs <code>./.githook.sh install</code> once after cloning because git config is local.</p>
_FOOT
