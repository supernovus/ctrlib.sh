## Build tools environment commands.

[ -z "$CTRLIB_LIB_DIR" ] && echo "Container init not loaded." && exit 100

need docker

[ -n "$CTRLIB_ENV_LIB" ] && return
CTRLIB_ENV_LIB=1

[ -z "$CTRLIB_BT_IMAGE" ] && CTRLIB_BT_IMAGE="luminaryn/buildtools"
[ -z "$CTRLIB_BT_NAME" ] && CTRLIB_BT_NAME="buildtools_session"
[ -z "$CTRLIB_DOCKER_NET" ] && CTRLIB_DOCKER_NET="${CTRLIB_PROJECT_NAME}_default"

register_command 'env' 'build_tools' 1 "Run buildtools commands."
register_help_func 'build_tools' 'bt_help'
register_command 'shell' 'build_tools_shell' 1 "Open a quick buildtools shell."
register_help_func 'build_tools_shell' 'bt_shell_help'

bt_help () {
  echo "Build tools commands:"
  echo
  echo "  env enter [options...]      Enter a one-time buildtools container."
  echo "  env start [options...]      Start a persistent buildtools container."
  echo "  env stop                    Stop a running buildtools container."
  echo "  env run [-i] ...            Run a command on a buildtools container."
  echo "  env update                  Update the buildtools container."
  echo
  echo "Options for 'start' command:"
  echo "  -t <to>   Container timeout (default '30m', MUST be first option.)"
  echo
  echo "Options for 'enter' and 'start' commands:"
  echo "  -proj        Connect to the $CTRLIB_DOCKER_NET network."
  echo "  -net <name>  Connect to the specified Docker network."
  echo "  -v <mount>   Mount a volume (may be passed more than once.)"
  echo "  -p <port>    Map a port (may be passed more than once.)"
  if [ -n "$CTRLIB_BT_FLAGS" ]; then
    echo
    echo " The following options are always implicitly used:"
    echo "  $CTRLIB_BT_FLAGS"
  fi
  echo
  echo "Options for 'run' command:"
  echo "  -i           Run the command interactively, like a shell."
  exit 1
}

bt_shell_help () {
  echo "Open a simple build tools shell with access to project network."
  echo
  echo "There are no options for this, as it's simply an alias to:"
  echo
  echo "  env enter -proj"
  echo
  exit 1
}

build_tools() {
  [ $# -lt 1 ] && show_help -e env
  BTCMD=$1
  shift
  case $BTCMD in
    enter)
      enter_buildtools "$@"
    ;;
    start)
      start_buildtools "$@"
    ;;
    stop)
      stop_buildtools "$@"
    ;;
    run)
      exec_buildtools "$@"
    ;;
    update)
      update_buildtools
    ;;
    *)
      show_help -e env
    ;;
  esac
}

update_buildtools () {
  docker pull $CTRLIB_BT_IMAGE
}

run_buildtools () {
  BT_CMD=/bin/bash
  BT_FLAGS="--rm"
  ARGS=""
  while [ "$#" -gt 0 ]; do
    case $1 in
      -n)
        BT_FLAGS="$BT_FLAGS --name $2"
        shift
        shift
      ;;
      -d)
        BT_FLAGS="$BT_FLAGS -d"
        shift
      ;;
      -i|-it)
        BT_FLAGS="$BT_FLAGS -it"
        shift
      ;;
      -proj|-db)
        BT_FLAGS="$BT_FLAGS --net $CTRLIB_DOCKER_NET"
        shift
      ;;
      -host)
        BT_FLAGS="$BT_FLAGS --net=host --cap-add=NET_ADMIN"
      ;;
      -net)
        BT_FLAGS="$BT_FLAGS --net $2"
        shift
        shift
      ;;
      -v)
        BT_FLAGS="$BT_FLAGS -v $2"
        shift
        shift
      ;;
      -p)
        BT_FLAGS="$BT_FLAGS -p $2"
        shift
        shift
      ;;
      *)
        break;
      ;;
    esac
  done
  [ -n "$CTRLIB_BT_FLAGS" ] && BT_FLAGS="$BT_FLAGS $CTRLIB_BT_FLAGS"
  docker run $BT_FLAGS $CTRLIB_BT_IMAGE $@
}

start_buildtools () {
  BT_TIMEOUT=30m
  if [ "$1" = "-t" ]; then
    BT_TIMEOUT="$2"
    shift;
    shift;
  fi
  run_buildtools -d -n $CTRLIB_BT_NAME $@ /bin/sleep $BT_TIMEOUT
}

stop_buildtools () {
  docker kill $CTRLIB_BT_NAME
}

is_bt_running () {
  list_containers | grep $CTRLIB_BT_NAME >/dev/null 2>&1
}

exec_buildtools () {
  is_bt_running
  if [ $? -eq 0 ]; then
    FLAGS=""
    [ "$1" = "-i" -o "$1" = "-it" ] && FLAGS="-it" && shift;
    docker exec $FLAGS $CTRLIB_BT_NAME $@
  else
    run_buildtools $@
  fi
}

enter_buildtools ()
{
  run_buildtools -it $@ /bin/bash
}

build_tools_shell () {
  enter_buildtools -proj
}

mark_loaded env

