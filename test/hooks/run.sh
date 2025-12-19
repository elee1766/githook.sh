#!/bin/sh
# hook integration test runner

set -e

HOOKS_TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$HOOKS_TEST_DIR")")"

# build first
echo "building githook.sh..."
(cd "$PROJECT_DIR" && make build)

passed=0
failed=0

for test_file in "$HOOKS_TEST_DIR"/[0-9]*.sh; do
    [ -f "$test_file" ] || continue
    if sh "$test_file"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        echo "FAILED: $(basename "$test_file")"
    fi
done

echo
echo "---"
echo "passed: $passed"
echo "failed: $failed"

[ $failed -eq 0 ] || exit 1
