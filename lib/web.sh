## Web server container functions.

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::use ctrlib::docker

lum::lib ctrlib::web $CTRLIB_VER

lum::fn ctrlib::web::php -t 0 13
#$ [[container]]
#
# Set the primary PHP container
#
# ((container))      The container name to use.
#                If not specified, we will look for one with the name:
#                ``${CTRLIB_PROJECT_NAME}_php_1``
#
ctrlib::web::php() {
  if [ -z "$1" ]; then
    CTRLIB_PHP_CONTAINER="${CTRLIB_PROJECT_NAME}_php_1"
  else
    CTRLIB_PHP_CONTAINER="$1"
  fi
  ctrlib::docker::alias php $CTRLIB_PHP_CONTAINER
}

lum::fn ctrlib::web::nginx -t 0 13
#$ [[container]]
#
# Set the primary nginx container
#
# ((container))      The container name to use.
#                If not specified, we will look for one with the name:
#                ``${CTRLIB_PROJECT_NAME}_nginx_1``
#
ctrlib::web::nginx() {
  if [ -z "$1" ]; then
    CTRLIB_NGINX_CONTAINER="${CTRLIB_PROJECT_NAME}_nginx_1"
  else
    CTRLIB_NGINX_CONTAINER="$1"
  fi
  #container_alias nginx $CTRLIB_NGINX_CONTAINER
}

lum::fn ctrlib::web::reload 0 -A reload CMD
#$ [[service]]
#
# Reload service configuration files
#
# ((service))      A single service to reload.
#              ``php``   = The default PHP service.
#              ``nginx`` = The default nginx service.
#
#              If not specified, reloads all services.
#
# Individual control scripts may add their own services
# by overriding the ``reload`` alias.
#
ctrlib::web::reload() {
  if [ -n "$1" ]; then
    case $1 in
      php)
        reload_php
      ;;
      nginx)
        reload_nginx
      ;;
    esac
  else
    reload_php
    reload_nginx
  fi
}

lum::fn ctrlib::web::reload::php
#$ <<container>>
#
# Reload a specified PHP container
#
ctrlib::web::reload::php() {
  [ $# -ne 1 ] && lum::help::usage
  docker exec $1 /bin/bash -c 'kill -USR2 1'
}

lum::fn ctrlib::web::php::reload
#$
#
# Reload the default PHP container
# Does nothing if ``ctrlib::web::php`` was never ran.
#
ctrlib::web::php::reload() {
  [ -n "$CTRLIB_PHP_CONTAINER" -a "$CTRLIB_PHP_CONTAINER" != "0" ] && reload_php_container $CTRLIB_PHP_CONTAINER
}

lum::fn ctrlib::web::reload::nginx
#$ <<container>>
#
# Reload a specified nginx container
#
ctrlib::web::reload::php() {
  [ $# -ne 1 ] && lum::help::usage
  docker exec $1 nginx -s reload
}

lum::fn ctrlib::web::nginx::reload
#$
#
# Reload the default nginx container
# Does nothing if ``ctrlib::web::nginx`` was never ran.
#
ctrlib::web::nginx::reload() {
  [ -n "$CTRLIB_NGINX_CONTAINER" -a "$CTRLIB_NGINX_CONTAINER" != "0" ] && reload_nginx_container $CTRLIB_NGINX_CONTAINER
}

