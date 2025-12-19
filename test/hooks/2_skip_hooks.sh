#!/bin/sh
. "$(dirname "$0")/functions.sh"
setup

# Should not setup hooks when GITHOOK=0
GITHOOK=0 ./.githook.sh install 2>/dev/null || true
expect_hooksPath_to_be ""

# Now install normally
install
expect_hooksPath_to_be ".githook/_"

# Create hook that would fail
echo "echo file > file.txt" | sh
git add file.txt
echo '#!/bin/sh
echo "pre-commit" && exit 1' > .githook/pre-commit
chmod +x .githook/pre-commit

# Should fail without GITHOOK=0
expect 1 "git commit -m foo"

# Should succeed with GITHOOK=0
expect 0 "GITHOOK=0 git commit -m bar"

ok
