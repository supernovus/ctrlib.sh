#$< ctrlib::env
# Build tools environment commands.

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::use ctrlib::docker

lum::var::need CTRLIB_PROJECT_NAME

lum::var -P CTRLIB_BT_ \
  IMAGE =? "luminaryn/buildtools" \
  NAME  =? "buildtools_session" \
  NET   =? "${CTRLIB_PROJECT_NAME}_default" \
  -a FLAGS
 
lum::fn ctrlib::env 0 -A env CMD -h opts more
#$ <<command>> `{...}`
#
# Run a BuildTools environment command
#
# Build tools commands:
#
#   $i(enter); `{...}`         Enter a one-time buildtools container.
#   $i(shell);             A shell in $var(CTRLIB_DOCKER_NET); net.
#   $i(start); `{...}`         Start a persistent buildtools container.
#   $i(stop);              Stop a running buildtools container.
#   $i(exec); `{...}`          Run a command on a buildtools container.
#   $i(run); `{...}`           Start a container and run a command on it.
#   $i(update);            Update the $var(CTRLIB_BT_IMAGE); container.
#
#$line(See also);
# $see(env-enter);, $see(env-start);, $see(env-exec);, $see(env-run);.
#
ctrlib::env() {
  [ $# -lt 1 ] && lum::help::usage
  lum::fn::run 3 ctrlib::env:: "$@"
}

lum::fn ctrlib::env::flags
#$ <<args...>>
#
# Add all arguments as default BuildTools options.
#
ctrlib::env::flags() {
  [ $# -eq 0 ] && lum::help::usage
  CTRLIB_BT_FLAGS+=("$@")
}

lum::fn ctrlib::env::update 4 -a env-update 1 0
#$ - Update the buildtools container
#
ctrlib::env::update() {
  docker pull $CTRLIB_BT_IMAGE
}

lum::fn ctrlib::env::run 0 -a env-run 1 0
#$ [[options...]] <<command>> [[params...]]
#
# Start a buildtools container, then run a command on it.
#
# ((options))      Options for the container environment.
#              See $see(env,opts); for details.
# ((command))      The command to run.
#
# ((params))       Parameters for the command.
#
ctrlib::env::run() {
  local btCmd=/bin/bash 
  local -a btFlags=('--rm')
  ARGS=""
  while [ "$#" -gt 0 ]; do
    case $1 in
      -n)
        btFlags+=('--name' "$2")
        shift
        shift
      ;;
      -d)
        btFlags+=('-d')
        shift
      ;;
      -i|-it)
        btFlags+=('-it')
        shift
      ;;
      -proj|-db)
        btFlags+=('--net' "$CTRLIB_DOCKER_NET")
        shift
      ;;
      -host)
        btFlags+=('--net=host' '--cap-add=NET_ADMIN')
      ;;
      -net)
        btFlags+=('--net' "$2")
        shift
        shift
      ;;
      -v)
        btFlags+=('-v' "$2")
        shift
        shift
      ;;
      -p)
        btFlags+=('-p' "$2")
        shift
        shift
      ;;
      *)
        break;
      ;;
    esac
  done
  [ -n "$CTRLIB_BT_FLAGS" ] && btFlags+=("${CTRLIB_BT_FLAGS[@]}")
  docker run "${btFlags[@]}" $CTRLIB_BT_IMAGE "$@"
}

#$ ctrlib::env,opts - Options for ``env-run`` and ``env-start``
#
# ``-n``      <<name>>    The name for the container.
# ``-d``             Run in detached mode.
# ``-i``             Run in interactive mode. 
#                    Alias: ``-it``
# ``-proj``          Run in $var(CTRLIB_DOCKER_NET); network.
#                    Alias: ``-db``
# ``-host``          Run in **host** network (admin-only).
# ``-net``    <<net>>    Run in specified network.
# ``-v``      <<mount>>  Map a ``src:dest`` volume to the host.
# ``-p``      <<port>>   Map a ``src:dest`` port to the host.
#
# Default flags: $var(CTRLIB_BT_FLAGS);
#
#: ctrlib::env,opts

lum::fn ctrlib::env::start 0 -a env-start 1 0 -h 0 more
#$ [[options...]]
#
# Start a persistent buildtools container
#
# ((options))      Options for the container.
#              ``-t`` <<timeout>>  Timeout the container after a set time.
#              Use `s,m,h,d` suffix to specify unit of time. Default: ``30m``
#
#              Also supports most options from $see(env,opts);,
#              $b(except);: ``-n`` and ``-d``, which are already specified.
#
ctrlib::env::start() {
  local timeout=30m
  if [ "$1" = "-t" ]; then
    timeout="$2"
    shift;
    shift;
  fi
  ctrlib::env::run -d -n $CTRLIB_BT_NAME "$@" /bin/sleep $timeout
}

lum::fn ctrlib::env::stop 4 -a env-stop 1 0
#$ - Stop the persistent buildtools container
#
ctrlib::env::stop() {
  docker kill $CTRLIB_BT_NAME
}

lum::fn ctrlib::env::isRunning 4
#$ - See if a persistent buildtools container is running
#
ctrlib::env::isRunning() {
  ctrlib::docker::isRunning $CTRLIB_BT_NAME
}

lum::fn ctrlib::env::exec 0 -a env-exec 1 0
#$ [[options]] <<command>> [[params...]]
# 
# Run a command on a buildtools container.
# If there is a persistent container running, this uses it.
# Otherwise this forwards all arguments to ``env-run``.
#
# ((options))      Options for the execution environment.
#                  ``-i | -it``  Run in interactive mode.
#                  
# ((command))      The command to run.
#
# ((params))       Parameters for the command.
#
ctrlib::env::exec() {
  ctrlib::env::isRunning
  if [ $? -eq 0 ]; then
    local flags=""
    [ "$1" = "-i" -o "$1" = "-it" ] && flags="-it" && shift;
    docker exec $flags $CTRLIB_BT_NAME "$@"
  else
    ctrlib::env::run "$@"
  fi
}

lum::fn ctrlib::env::enter 0 -a env-enter 1 0
#$ [[options...]]
#
# Create a new buildtools environment and start a bash shell session
#
# ((options))      Options for the container environment.
#              See ``env.opts`` for details.
#              Note: ``-it`` is specified automatically.
#
ctrlib::env::enter()
{
  ctrlib::env::run -it "$@" /bin/bash
}

lum::fn ctrlib::env::shell 0 -a env-shell 1 0
#$
#
# A bash shell with the $var(CTRLIB_DOCKER_NET); network
#
# This is just an alias for ``env-enter -proj``
#
ctrlib::env::shell() {
  ctrlib::env::enter -proj
}

lum::fn ctrlib::env::root-shell 0 -a env-root-shell 1 0
#$
#
# A bash shell with access to the $i(host); network and filesystem
#
# This is just an alias for ``env-enter -host -v /:/mnt/host``
#
ctrlib::env::root-shell() {
  ctrlib::env::enter -host -v /:/mnt/host
}
