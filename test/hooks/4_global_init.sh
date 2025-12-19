#!/bin/sh
. "$(dirname "$0")/functions.sh"
setup
install

expect_hooksPath_to_be ".githook/_"

# Create file to commit
echo "echo file > file.txt" | sh
git add file.txt

# Create hook that would fail
echo '#!/bin/sh
echo "pre-commit" && exit 1' > .githook/pre-commit
chmod +x .githook/pre-commit

# Should fail without global init
expect 1 "git commit -m foo"

# Create global init that sets GITHOOK=0
mkdir -p "$testDir/.config/githook"
echo "export GITHOOK=0" > "$testDir/.config/githook/init.sh"

# Should succeed with global init setting GITHOOK=0
# Use HOME override to point to our test config
expect 0 "HOME=$testDir git commit -m bar"

ok
