#!/bin/sh
. "$(dirname "$0")/functions.sh"
setup
install

expect_hooksPath_to_be ".githook/_"

# Create file to commit
echo "echo file > file.txt" | sh
git add file.txt

# Create hook that succeeds
echo '#!/bin/sh
echo "pre-commit passes"' > .githook/pre-commit
chmod +x .githook/pre-commit

# Should succeed
expect 0 "git commit -m foo"

ok
