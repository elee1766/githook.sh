include(`_base.m4')dnl
_HEAD(`git hooks made easier. simple, lightweight, and portable.',`githook.sh')
<h1>githook.sh</h1>
<p>git hooks made easier. simple, lightweight, and portable.</p>
<p>like <a href="https://github.com/typicode/husky">husky</a>, but without npm.</p>
<p><a href="/docs">docs</a> · <a href="/.githook.sh">view</a></p>
<h2>quick setup</h2>
_CODE(`curl -sSL https://githook.sh | sh')
<p>or with wget:</p>
_CODE(`wget -qO- https://githook.sh | sh')
<p>this downloads .githook.sh to the current directory if not already, then runs install to setup hooks locally</p>
<h2>manual setup</h2>
_CODE(`curl -sSL https://githook.sh -o .githook.sh
chmod +x .githook.sh
./.githook.sh install')
<h2>commands</h2>
_CODE(`./.githook.sh install       set up git hooks (run once per clone)
./.githook.sh uninstall     remove git hooks configuration
./.githook.sh check         check for updates
./.githook.sh update        download latest version')
<h2>adding hooks</h2>
<p>create executable scripts in .githook/ named after the git hook:</p>
_CODE(`echo '"'"'#!/bin/sh
npm test'"'"' > .githook/pre-commit
chmod +x .githook/pre-commit')
<p>scripts must be executable and start with a shebang.</p>
<h2>environment variables</h2>
_CODE(`GITHOOK=0        skip hooks
GITHOOK_DEBUG=1  show debug output')
<h2>migrating from husky</h2>
<p>hooks are auto-migrated during setup if .husky/ is detected, or run manually:</p>
_CODE(`./.githook.sh migrate husky')
<h2>repository</h2>
<p><a href="https://github.com/elee1766/githook.sh">github.com/elee1766/githook.sh</a></p>
<h2>license</h2>
<p><a href="https://unlicense.org/">unlicense</a> (public domain)</p>
_FOOT
