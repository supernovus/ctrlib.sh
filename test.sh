#!/bin/bash

CTRLIB_CONTAINER_CONF=/etc/docker/fakeservice.yaml
CTRLIB_SERVICE_NAME=fakeservice

. ./lib/init.sh

USERLIBS="$(get_user_config_dir)/$SCRIPTNAME"

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

use_lib default_set
register_compose_commands

use_app_libs "$(dirname $0)/test_lib"
use_lib example

parse_commands "$@"

