#!/bin/bash

CTRLIB_CONTAINER_CONF=/etc/docker/fakeservice.yaml
CTRLIB_PROJECT_NAME=fakeservice

. ./lib/init.sh

USERLIBS="$(get_user_config_dir)/$SCRIPTNAME"
TESTDIR="$(dirname $0)/_test"

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

use_lib docker web
use_user_libs
register_compose_commands

use_app_libs "$TESTDIR/lib"
use_app_conf "$TESTDIR/conf"
use_lib example
use_lib --conf example

parse_commands "$@"
