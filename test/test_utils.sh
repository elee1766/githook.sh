# utils tests

echo "is_valid_hook:"
assert_true githook_is_valid_hook "pre-commit"
assert_true githook_is_valid_hook "post-merge"
assert_true githook_is_valid_hook "pre-push"
assert_true githook_is_valid_hook "commit-msg"
assert_false githook_is_valid_hook "invalid-hook"
assert_false githook_is_valid_hook ""
assert_false githook_is_valid_hook " "
assert_false githook_is_valid_hook "/"
assert_false githook_is_valid_hook ".."
assert_false githook_is_valid_hook "../etc/passwd"
assert_false githook_is_valid_hook "pre-commit/"
assert_false githook_is_valid_hook "/pre-commit"
assert_false githook_is_valid_hook "pre commit"
assert_false githook_is_valid_hook "pre-commit; rm -rf /"
assert_false githook_is_valid_hook 'pre-commit`whoami`'
assert_false githook_is_valid_hook 'pre-commit$(whoami)'

echo ""
echo "is_disabled:"
GITHOOK=0
assert_true githook_is_disabled
GITHOOK=1
assert_false githook_is_disabled
GITHOOK=
assert_false githook_is_disabled
unset GITHOOK
assert_false githook_is_disabled

echo ""
echo "is_debug_enabled:"
GITHOOK_DEBUG=1
assert_true githook_is_debug_enabled
GITHOOK_DEBUG=
assert_false githook_is_debug_enabled
unset GITHOOK_DEBUG
