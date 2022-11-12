## Docker functions.

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::var::need CTRLIB_PROJECT_NAME
lum::use ctrlib::core

declare -gA CTRLIB_DOCKER_ALIAS

lum::lib ctrlib::docker $CTRLIB_VER

if [ -z "$DOCKER_COMPOSE" ]; then
  lum::var::need CTRLIB_CONTAINER_CONF
  DOCKER_COMPOSE="docker-compose -p $CTRLIB_PROJECT_NAME -f $CTRLIB_CONTAINER_CONF"
  ctrlib::debug 1 "Using: $DOCKER_COMPOSE"
fi

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
  if [ "$#" -eq 0 ]; then
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
  [ $# -ne 2 ] && lum::help::usage
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
  [ "$#" -ne 1 ] && echo "get_container <name>" && exit 181
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
  [ "$#" -ne 1 ] && show_help -e enter
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
  $DOCKER_COMPOSE "$@"
}

lum::fn ctrlib::docker::reboot 0 -A reboot CMD
#$ <<name>>
#
# Restart a specified container
#
ctrlib::docker::reboot() {
  [ "$#" -ne 1 ] && show_help -e restart-container
  local CN="$(ctrlib::docker::get $1)"
  $DOCKER_COMPOSE restart "$CN"
}

lum::fn ctrlib::docker::update 0 -A update CMD
#$
#
# Update container images
#
ctrlib::docker::update() {
  echo "Updating containers."
  $DOCKER_COMPOSE pull
  echo "Use 'sudo $SCRIPTNAME restart' to ensure newest containers are running."
}

lum::fn ctrlib::docker::start 0 -a start-docker 0 0
#$
#
# Start all containers with docker
#
ctrlib::docker::start() {
  $DOCKER_COMPOSE up
}

lum::fn ctrlib::docker::stop 0 -a stop-docker 0 0
#$ 
#
# Stop all containers with docker
#
ctrlib::docker::stop() {
  $DOCKER_COMPOSE down
}

lum::fn ctrlib::docker::restart 0 -a restart-docker 0 0
#$
#
# Restart all containers with docker
#
ctrlib::docker::restart() {
  $DOCKER_COMPOSE restart
}

