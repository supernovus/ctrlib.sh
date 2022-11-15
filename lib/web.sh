## Web server container functions.

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::use ctrlib::docker

lum::lib ctrlib::web $CTRLIB_VER

declare -a CTRLIB_PHP_CONTAINERS
declare -a CTRLIB_NGINX_CONTAINERS

lum::fn ctrlib::web::php 0 -t 0 13 -A php_container CONF
#$ [[container...]]
#
# Set the primary PHP container(s)
#
# ((container))      The container name to use.
#                If not specified, we will look for one with the name:
#                ``${CTRLIB_PROJECT_NAME}_php_1``
#
ctrlib::web::php() {
  if [ $# -eq 0 ]; then
    local CN="${CTRLIB_PROJECT_NAME}_php_1"
    CTRLIB_PHP_CONTAINERS+=("$CN")
    ctrlib::docker::alias php "$CN"
  else
    CTRLIB_PHP_CONTAINERS+=("$@")
  fi
}

lum::fn ctrlib::web::nginx 0 -t 0 13 -A nginx_container CONF
#$ [[container...]]
#
# Set the primary nginx container(s)
#
# ((container))      The container name to use.
#                If not specified, we will look for one with the name:
#                ``${CTRLIB_PROJECT_NAME}_nginx_1``
#
ctrlib::web::nginx() {
  if [ $# -eq 0 ]; then
    local CN="${CTRLIB_PROJECT_NAME}_nginx_1"
    CTRLIB_NGINX_CONTAINERS+=("$CN")
    ctrlib::docker::alias nginx "$CN"
  else
    CTRLIB_NGINX_CONTAINERS+=("$@")
  fi
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
# Reload the default PHP container(s)
# Does nothing if ``ctrlib::web::php`` was never ran.
#
ctrlib::web::php::reload() {
  local cont
  for cont in "${CTRLIB_PHP_CONTAINERS[@]}"; do
    ctrlib::web::reload::php $cont
  done
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
  local cont
  for cont in "${CTRLIB_NGINX_CONTAINERS[@]}"; do
    ctrlib::web::reload::nginx $cont
  done
}
