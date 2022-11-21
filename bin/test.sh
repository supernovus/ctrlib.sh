#!/bin/bash

TEST_BIN_DIR="$(dirname $0)"
TEST_ROOT="$TEST_BIN_DIR/.."

[ -z "$TEST_LUM_CORE" ] && TEST_LUM_CORE="$TEST_ROOT/../lum-core"

TEST_CONF="$TEST_ROOT/_test/conf"
TEST_LIBS="$TEST_ROOT/_test/lib"

CTRLIB_PROJECT_NAME=fakeservice

LUM_USAGE_STACK=1

. "$TEST_LUM_CORE/lib/core.sh"

lum::use::libdir "$TEST_ROOT/lib" ctrlib::
lum::use ctrlib::core

lum::user::appDir .ctrlib
USERLIBS="$(lum::user::conf 1)"

if [ "$1" = "--enable-env" ]; then
  mkdir -p $USERLIBS 2>/dev/null
  touch $USERLIBS/env.lib
  echo "Enabled 'env' library."
  exit 0
elif [ "$1" = "--disable-env" ]; then
  [ -f "$USERLIBS/env.lib" ] && rm $USERLIBS/env.lib
  echo "Disabled 'env' library."
  exit 0
fi

unset USERLIBS

lum::use::libdir "$TEST_LIBS"
lum::use::confdir "$TEST_CONF"
lum::use example --conf example

ctrlib::docker::registerCompose
lum::user::libs

[ $# -eq 0 ] && ctrlib::usage

lum::fn::run 1 "$@"
