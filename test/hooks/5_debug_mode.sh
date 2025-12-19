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
echo "pre-commit"' > .githook/pre-commit
chmod +x .githook/pre-commit

# Test GITHOOK=2 enables set -x (debug output)
output=$(GITHOOK=2 git commit -m foo 2>&1)
if echo "$output" | grep -q "^\+"; then
    ok
else
    error "expected set -x debug output with GITHOOK=2"
fi
