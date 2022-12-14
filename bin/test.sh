#!/bin/bash

CTRLIB_BIN_DIR="$(dirname $0)"
CTRLIB_ROOT="$TEST_BIN_DIR/.."

[ -z "$CTRLIB_LUM_CORE" ] && CTRLIB_LUM_CORE="$CTRLIB_ROOT/../lum-core"

LUM_USAGE_STACK=1

. "$CTRLIB_LUM_CORE/lib/core.sh"

lum::use::libdir "$CTRLIB_ROOT/lib" ctrlib::
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

. "$CTRLIB_ROOT/_test/init.sh"

lum::use example --conf example

ctrlib::docker::registerCompose
lum::user::libs

[ $# -eq 0 ] && ctrlib::usage

lum::fn::run 1 "$@"
