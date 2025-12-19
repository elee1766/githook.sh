# semver tests

echo "semver parsing:"
githook_semver "1.2.3"
assert_eq "$major" "1" "major=1"
assert_eq "$minor" "2" "minor=2"
assert_eq "$patch" "3" "patch=3"

githook_semver "0.0.0"
assert_eq "$major" "0" "0.0.0 major"
assert_eq "$minor" "0" "0.0.0 minor"
assert_eq "$patch" "0" "0.0.0 patch"

githook_semver "1.0.0-alpha"
assert_eq "$major" "1" "1.0.0-alpha major"
assert_eq "$prerelease" "alpha" "1.0.0-alpha prerelease"

githook_semver "1.0.0-alpha.1"
assert_eq "$prerelease" "alpha.1" "1.0.0-alpha.1 prerelease"

githook_semver "1.0.0-beta.2+build"
assert_eq "$prerelease" "beta.2+build" "prerelease includes build metadata"

echo ""
echo "invalid versions:"
githook_semver "not-a-version" && _result=0 || _result=$?
assert_eq "$_result" "1" "rejects non-version"

githook_semver "" && _result=0 || _result=$?
assert_eq "$_result" "1" "rejects empty"

githook_semver "1.2" && _result=0 || _result=$?
assert_eq "$_result" "1" "rejects incomplete version"

githook_semver "1.2.3.4" && _result=0 || _result=$?
assert_eq "$_result" "1" "rejects too many parts"

githook_semver "a.b.c" && _result=0 || _result=$?
assert_eq "$_result" "1" "rejects non-numeric"

githook_semver "-1.0.0" && _result=0 || _result=$?
assert_eq "$_result" "1" "rejects negative"

echo ""
echo "version comparison:"
githook_version_compare "1.0.0" "1.0.0"; assert_eq "$?" "0" "1.0.0 = 1.0.0"
githook_version_compare "2.0.0" "1.0.0"; assert_eq "$?" "1" "2.0.0 > 1.0.0"
githook_version_compare "1.0.0" "2.0.0"; assert_eq "$?" "2" "1.0.0 < 2.0.0"
githook_version_compare "1.1.0" "1.0.0"; assert_eq "$?" "1" "1.1.0 > 1.0.0"
githook_version_compare "1.0.1" "1.0.0"; assert_eq "$?" "1" "1.0.1 > 1.0.0"
githook_version_compare "1.0.0-alpha" "1.0.0"; assert_eq "$?" "2" "1.0.0-alpha < 1.0.0"
githook_version_compare "1.0.0" "1.0.0-alpha"; assert_eq "$?" "1" "1.0.0 > 1.0.0-alpha"
githook_version_compare "v1.0.0" "1.0.0"; assert_eq "$?" "0" "v prefix stripped"
