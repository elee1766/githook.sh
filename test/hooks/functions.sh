#!/bin/sh
# test helper functions for hook tests

set -eu

HOOKS_TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$HOOKS_TEST_DIR")")"

setup() {
    name="$(basename -- "$0")"
    testDir="/tmp/githook-test-$name"
    echo
    echo "-------------------"
    echo "+ $name"
    echo "-------------------"
    echo

    rm -rf "$testDir"
    mkdir -p "$testDir"
    cd "$testDir"

    git init --quiet
    git config user.email "test@test"
    git config user.name "test"
}

install() {
    cp "$PROJECT_DIR/.githook.sh" .githook.sh
    chmod +x .githook.sh
    ./.githook.sh install
}

expect() {
    set +e
    sh -c "$2"
    exitCode="$?"
    set -e
    if [ "$exitCode" != "$1" ]; then
        error "expect command \"$2\" to exit with code $1 (got $exitCode)"
    fi
}

expect_hooksPath_to_be() {
    hooksPath=$(git config core.hooksPath 2>/dev/null || echo "")
    if [ "$hooksPath" != "$1" ]; then
        error "core.hooksPath should be '$1', was '$hooksPath'"
    fi
}

error() {
    echo "ERROR: $1"
    exit 1
}

ok() {
    echo "OK"
}

cleanup() {
    rm -rf "/tmp/githook-test-*"
}
