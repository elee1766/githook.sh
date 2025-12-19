#!/bin/sh
# test runner

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$TESTS_DIR")"

# source all src files for testing
for f in "$PROJECT_DIR"/src/*.sh; do
    # skip header.sh (has set -e and shebang)
    case "$f" in */header.sh) continue ;; esac
    . "$f"
done

PASSED=0
FAILED=0

assert_eq() {
    if [ "$1" = "$2" ]; then
        PASSED=$((PASSED + 1))
        echo "  ok: $3"
    else
        FAILED=$((FAILED + 1))
        echo "  FAIL: $3"
        echo "    expected: $2"
        echo "    got: $1"
    fi
}

assert_true() {
    if "$@"; then
        PASSED=$((PASSED + 1))
        echo "  ok: $*"
    else
        FAILED=$((FAILED + 1))
        echo "  FAIL: $*"
    fi
}

assert_false() {
    if "$@"; then
        FAILED=$((FAILED + 1))
        echo "  FAIL: expected false: $*"
    else
        PASSED=$((PASSED + 1))
        echo "  ok: not $*"
    fi
}

# run all test files
for test_file in "$TESTS_DIR"/test_*.sh; do
    [ -f "$test_file" ] || continue
    echo ""
    echo "=== $(basename "$test_file") ==="
    . "$test_file"
done

echo ""
echo "---"
echo "passed: $PASSED"
echo "failed: $FAILED"

[ $FAILED -eq 0 ] || exit 1
