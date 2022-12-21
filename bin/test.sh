#!/bin/bash

CTRLIB_TEST_SH="$(realpath -e "$0")"
CTRLIB_BIN_DIR="$(dirname "$CTRLIB_TEST_SH")"
CTRLIB_PKG_DIR="$(dirname "$CTRLIB_BIN_DIR")"

[ -z "$CTRLIB_LUM_CORE" ] && CTRLIB_LUM_CORE="$CTRLIB_PKG_DIR/../lum-core"

. "$CTRLIB_LUM_CORE/lib/core.sh"

lum::use::libdir "$CTRLIB_PKG_DIR/lib" ctrlib::
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

. "$CTRLIB_PKG_DIR/_test/init.sh"

lum::use example --conf example

ctrlib::docker::registerCompose
lum::user::libs

[ $# -eq 0 ] && ctrlib::usage

lum::fn::run 1 "$@"
