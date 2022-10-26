## Web server container functions.

[ -z "$CTRLIB_INIT" ] && echo "Container init not loaded." && exit 100

need docker

register_command 'reload' 'reload_config' 1 "Reload the service configuration files." "[php|nginx]\n If you specify 'php' or 'nginx' only that will be reloaded.\n Otherwise we reload both if they are available."

use_php_container() {
  if [ -z "$1" ]; then
    CTRLIB_PHP_CONTAINER="${CTRLIB_PROJECT_NAME}_php_1"
  else
    CTRLIB_PHP_CONTAINER="$1"
  fi
  #container_alias php $CTRLIB_PHP_CONTAINER
}

use_nginx_container() {
  if [ -z "$1" ]; then
    CTRLIB_NGINX_CONTAINER="${CTRLIB_PROJECT_NAME}_nginx_1"
  else
    CTRLIB_NGINX_CONTAINER="$1"
  fi
  #container_alias nginx $CTRLIB_NGINX_CONTAINER
}

## You might want to override this in your individual scripts if needed.
reload_config() {
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

reload_php_container() {
  [ $# -ne 1 ] && echo "reload_php_container <container_name>" && exit 210
  docker exec $1 /bin/bash -c 'kill -USR2 1'
}

## You can also override individual functions like this one.
reload_php() {
  [ -n "$CTRLIB_PHP_CONTAINER" -a "$CTRLIB_PHP_CONTAINER" != "0" ] && reload_php_container $CTRLIB_PHP_CONTAINER
}

reload_nginx_container() {
  [ $# -ne 1 ] && echo "reload_nginx_container <container_name>" && exit 211
  docker exec $1 nginx -s reload
}

## Or this one.
reload_nginx() {
  [ -n "$CTRLIB_NGINX_CONTAINER" -a "$CTRLIB_NGINX_CONTAINER" != "0" ] && reload_nginx_container $CTRLIB_NGINX_CONTAINER
}

mark_loaded web

