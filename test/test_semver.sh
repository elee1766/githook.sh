# version comparison tests

echo "version comparison:"
githook_version_compare "1.0.0" "1.0.0"; assert_eq "$?" "0" "1.0.0 = 1.0.0"
githook_version_compare "2.0.0" "1.0.0"; assert_eq "$?" "1" "2.0.0 > 1.0.0"
githook_version_compare "1.0.0" "2.0.0"; assert_eq "$?" "2" "1.0.0 < 2.0.0"
githook_version_compare "1.1.0" "1.0.0"; assert_eq "$?" "1" "1.1.0 > 1.0.0"
githook_version_compare "1.0.1" "1.0.0"; assert_eq "$?" "1" "1.0.1 > 1.0.0"
githook_version_compare "v1.0.0" "1.0.0"; assert_eq "$?" "0" "v prefix stripped"
githook_version_compare "0.1.5" "0.1.4"; assert_eq "$?" "1" "0.1.5 > 0.1.4"
githook_version_compare "0.2.0" "0.1.9"; assert_eq "$?" "1" "0.2.0 > 0.1.9"
githook_version_compare "1.0.0" "0.99.99"; assert_eq "$?" "1" "1.0.0 > 0.99.99"
