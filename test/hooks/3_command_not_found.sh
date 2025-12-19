#!/bin/sh
. "$(dirname "$0")/functions.sh"
setup
install

expect_hooksPath_to_be ".githook/_"

# Test pre-commit with 127 exit code (command not found)
echo "echo file > file.txt" | sh
git add file.txt
echo '#!/bin/sh
exit 127' > .githook/pre-commit
chmod +x .githook/pre-commit

# Should fail (git returns 1 when hook fails, even if hook returns 127)
expect 1 "git commit -m foo"

ok
