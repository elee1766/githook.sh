#!/bin/sh
. "$(dirname "$0")/functions.sh"
setup
install

# Test core.hooksPath
expect_hooksPath_to_be ".githook/_"

# Test pre-commit blocks commit
echo "echo file > file.txt" | sh
git add file.txt
echo '#!/bin/sh
echo "pre-commit" && exit 1' > .githook/pre-commit
chmod +x .githook/pre-commit
expect 1 "git commit -m foo"

ok
