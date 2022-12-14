# Test init

lum::var CTRLIB_TEST_DIR =? "$(dirname $BASH_SOURCE)"

CTRLIB_PROJECT_NAME=fakeproject
CTRLIB_SERVICE_NAME=fakeservice

lum::use::libdir "$CTRLIB_TEST_DIR/lib"
lum::use::confdir "$CTRLIB_TEST_DIR/conf"

