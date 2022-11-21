#@lib: ctrlib::docker
#@desc: Docker functions.

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::use ctrlib::core

declare -gA CTRLIB_DOCKER_ALIAS

declare -ga CTRLIB_DOCKER_COMPOSE_CMD
declare -ga CTRLIB_DOCKER_COMPOSE_OPTS
declare -ga CTRLIB_DOCKER_COMPOSE_CONF

lum::fn ctrlib::docker::compose::reset 
#$ <<what>>
#
# Reset docker compose settings
#
# ((what))        Bitwise flags for what to reset.
#             ``1``  = Reset base command line.
#             ``2``  = Reset default config files.
#             ``4``  = Reset default compose options. 
#
ctrlib::docker::compose::reset() {
  [ $# -eq 0 ] && lum::help::usage
  local -i what="$1" CL=1 CF=2 CO=4
  lum::flag::is $what $CL && CTRLIB_DOCKER_COMPOSE_CMD=()
  lum::flag::is $what $CF && CTRLIB_DOCKER_COMPOSE_CONF=()
  lum::flag::is $what $CO && CTRLIB_DOCKER_COMPOSE_OPTS=()
}

lum::fn ctrlib::docker::compose::opts 0 -A compose_opts CONF
#$ <<opts...>>
#
# Add all arguments as docker-compose options
#
ctrlib::docker::compose::opts() {
  [ $# -eq 0 ] && lum::help::usage
  CTRLIB_DOCKER_COMPOSE_OPTS+=("$@")
}

lum::fn ctrlib::docker::compose::conf 0 -A compose_conf CONF
#$ <<confFile...>>
#
# Add all arguments as docker-compose configuration files
#
ctrlib::docker::compose::conf() {
  [ $# -eq 0 ] && lum::help::usage
  CTRLIB_DOCKER_COMPOSE_CONF+=("$@")
}

lum::fn ctrlib::docker::compose::cmd 0 -t 0 7
#$ [[opts...]]
#
# Build/get the base **docker-compose** command line
#
# ((opts))         Options changing the behaviour.
#              ``-f``           → If specified, always rebuild.
#              ``-e``           → If specified, echo the value.
#              ``-E`` <<exec>>  → Path to the docker-compose executable.
#              ``-V`` <<var>>   → Make a global alias with this name.
#
ctrlib::docker::compose::cmd() {
  local execCmd="${CTRLIB_DOCKER_COMPOSE_EXEC:-docker-compose}" exportVar
  local -i echoCmd=0
  local -n dcCmds=CTRLIB_DOCKER_COMPOSE_CMD
  local -n dcOpts=CTRLIB_DOCKER_COMPOSE_OPTS
  local -n dcConf=CTRLIB_DOCKER_COMPOSE_CONF

  while [ $# -gt 0 ]; do
    case "$1" in
      -f)
        lum::docker::compose::reset 1
      ;;
      -e)
        echoCmd=1
      ;;
      -E)
        [ $# -lt 2 ] && lum::help::usage
        execCmd="$2"
        shift
      ;;
      -V)
        [ $# -lt 2 ] && lum::help::usage
        exportVar="$2"
        shift
      ;;
      *)
        echo "unknown option: $1" >&2
        lum::help::usage
      ;;
    esac
    shift
  done

  if [ "${#dcCmds[@]}" -eq 0 ]; then
    dcCmds=("$execCmd")
    [ -n "$CTRLIB_PROJECT_NAME" ] && dcCmds+=(-p "$CTRLIB_PROJECT_NAME")
    local dc
    for dc in "${dcConf}"; do
      dcCmds+=(-f "$dc")
    done
    [ "${#dcOpts[@]}" -gt 0 ] && dcCmds+=("${dcOpts[@]}")
  fi

  [ "$echoCmd" = "1" ] && echo "${dcCmds[@]}"
  [ -n "$exportVar" ] && declare -gn "$exportVar"=CTRLIB_DOCKER_COMPOSE_CMD
  return 0
}

lum::fn ctrlib::docker::registerCompose 
#$
#
# Register start, stop, and restart commands using docker-compose
#
ctrlib::docker::registerCompose() {
  local hide="${1:-0}"
  lum::fn::alias ctrlib::docker::start start CMD
  lum::fn::alias ctrlib::docker::stop stop CMD
  lum::fn::alias ctrlib::docker::restart restart CMD
}

lum::fn ctrlib::docker::registerListAlias
#$ <<command>>
#
# Register a command to call ``ctrlib::docker::lsAlias``.
#
ctrlib::docker::registerListAlias() {
  [ $# -lt 1 ] && lum::help::usage
  lum::fn::alias ctrlib::docker::lsAlias "$1" CMD
}

lum::fn ctrlib::docker::list 0 -A list CMD
#$ `{...}`
#
# Show a list of docker containers
#
ctrlib::docker::list() {
  if [ $# -eq 0 ]; then
    docker ps --format "table {{.ID}}\t{{.Names}}"
  else
    docker ps "$@"
  fi
}

lum::fn ctrlib::docker::alias 0 -A container_alias CONF
#$ <<alias>> <<container>>
#
# Make an container alias for use in other commands.
#
ctrlib::docker::alias() {
  [ $# -lt 2 ] && lum::help::usage
  CTRLIB_DOCKER_ALIAS[$1]=$2
}

lum::fn ctrlib::docker::get
#$ <<name>>
#
# Return the container name in the ``STDOUT``.
# 
# ((name))    Name or alias we want.
#         If it is an alias, we'll return the real name.
#         If it's already the real name it's returned as is.
#
ctrlib::docker::get() {
  [ $# -eq 0 ] && echo "get_container <name>" && exit 181
  if [ -n "${CTRLIB_DOCKER_ALIAS[$1]}" ]; then
    echo "${CTRLIB_DOCKER_ALIAS[$1]}"
  else
    echo "$1"
  fi
}

lum::fn ctrlib::docker::lsAlias
#$
#
# List container aliases
#
ctrlib::docker::lsAlias() {
  local key val 
  local AC="$(lum::colour cyan)" 
  local FC="$(lum::colour green)" 
  local EC="$(lum::colour end)"
  for key in ${!CTRLIB_DOCKER_ALIAS[@]}
  do 
    val=${CTRLIB_DOCKER_ALIAS[$key]}
    echo "$AC$(lum::str::pad 20 "$key")$EC → $VC$val$EC"    
  done
}

lum::fn ctrlib::docker::enter 0 -A enter CMD
#$ <<name>>
#
# Enter a shell inside a container
#
# ((name))    The container name or alias.
#
ctrlib::docker::enter() {
  [ $# -eq 0 ] && lum::help::usage
  local CN="$(ctrlib::docker::get $1)"
  docker exec -it "$CN" /bin/bash
}

lum::fn ctrlib::docker::clean 0 -A clean CMD
#$
#
# Clean up stale container images
#
ctrlib::docker::clean() {
  docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
  docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
}

lum::fn ctrlib::docker::compose 0 -a compose 0 0
#$ `{...}`
#
# Run docker-compose commands.
#
ctrlib::docker::compose() {
  ctrlib::docker::compose::cmd
  #echo "» " "${CTRLIB_DOCKER_COMPOSE_CMD[@]}" "---" "$@"
  "${CTRLIB_DOCKER_COMPOSE_CMD[@]}" "$@"
}

lum::fn ctrlib::docker::reboot 0 -A reboot CMD
#$ <<name>>
#
# Restart a specified container
#
ctrlib::docker::reboot() {
  [ $# -eq 0 ] && lum::help::usage
  local CN="$(ctrlib::docker::get $1)"
  ctrlib::docker::compose restart "$CN"
}

lum::fn ctrlib::docker::update 0 -A update CMD
#$ [[opts]]
#
# Update container images
#
# ((opts))        Options for pull command
#
ctrlib::docker::update() {
  local -a opts
  [ "${#CTRLIB_DOCKER_PULL_OPTS[@]}" -gt 0 ] && opts=("${CTRLIB_DOCKER_PULL_OPTS[@]}")
  echo "Updating containers..."
  ctrlib::docker::compose pull "${opts[@]}"
  echo "Use 'sudo $SCRIPTNAME restart' to ensure newest containers are running."
}

lum::fn ctrlib::docker::start 0 -a start-docker 0 0
#$
#
# Start all containers with docker
#
ctrlib::docker::start() {
  ctrlib::docker::compose up
}

lum::fn ctrlib::docker::stop 0 -a stop-docker 0 0
#$ 
#
# Stop all containers with docker
#
ctrlib::docker::stop() {
  ctrlib::docker::compose down
}

lum::fn ctrlib::docker::restart 0 -a restart-docker 0 0
#$
#
# Restart all containers with docker
#
ctrlib::docker::restart() {
  ctrlib::docker::compose restart
}

lum::fn ctrlib::docker::isRunning
#$ <<name>>
#
# See if a persistent buildtools container is running
#
ctrlib::docker::isRunning() {
  [ $# -eq 0 ] && lum::help::usage
  local CN="$(ctrlib::docker::get $1)"
  ctrlib::docker::list | grep -sq $CN
}

lum::fn ctrlib::docker::compose::install-static 0 -a update-docker-compose 0 0
#$ [[dest=/usr/local/bin/docker-compose]]
#
# Install docker-compose binary
#
# ((dest))        The destination file.
#             If not specified tries ``$DOCKER_COMPOSE_DEST``;
#             If neither are found uses default.
#
ctrlib::docker::compose::install-static() {
  local DEFDEST="${DOCKER_COMPOSE_DEST:-/usr/local/bin/docker-compose}"
  local dest="${1:-$DEFDEST}"
  local dsys="$(uname -s)" darch="$(uname -m)"
  local DEFREPO="https://github.com/docker/compose/releases/download"
  local DEFGVER="https://api.github.com/repos/docker/compose/releases/latest"
  local repo="${DOCKER_COMPOSE_REPO:-$DEFREPO}"
  local getver="${DOCKER_COMPOSE_GET_VER:-$DEFGVER}"
  local compver="$(curl --silent $getver | jq -r .tag_name)"
  [ -z "$compver" ] && echo "Version could not be determined" && exit 100
  TMPFILE=$(mktemp)
  curl -L $repo/$compver/docker-compose-$dsys-$darch -o $TMPFILE
  [ $? -ne 0 ] && echo "could not download" && exit 100
  mv $TMPFILE $dest
  [ $? -ne 0 ] && echo "could not install" && exit 100
  chmod 755 $dest
}
