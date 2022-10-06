## Docker functions.

[ -z "$CTRLIB_INIT" ] && echo "Container init not loaded." && exit 100

need_conf CTRLIB_SERVICE_NAME

if [ -z "$DOCKER_COMPOSE" ]; then
  need_conf CTRLIB_CONTAINER_CONF
  DOCKER_COMPOSE="docker-compose -p $CTRLIB_PROJECT_NAME -f $CTRLIB_CONTAINER_CONF"
  debug "Using: $DOCKER_COMPOSE"
fi

register_command 'list' 'list_containers' 1 "List running containers."
register_command 'restart-container' 'restart_container' 1 "Restart a specified container." "<container>\n Pass the short container name."
register_command 'compose' 'docker_compose' 1 "Run a docker-compose command." "<command> [options...] <container>"
register_command 'enter' 'enter_container' 1 "Enter a specified container." "<container>\n Pass the container name or id we want to enter."
register_command 'update' 'update_containers' 1 "Update the containers."
register_command 'clean' 'clean_docker' 1 "Clean up stale Docker images."

register_compose_commands() {
  register_command 'start' 'start_containers_dc' 1 "Start the $CTRLIB_PROJECT_NAME containers."
  register_command 'stop' 'stop_containers_dc' 1 "Stop the $CTRLIB_PROJECT_NAME containers."
  register_command 'restart' 'restart_containers_dc' 1 "Restart the $CTRLIB_PROJECT_NAME containers."
}

list_containers() {
  if [ "$#" -eq 0 ]; then
    docker ps --format "table {{.ID}}\t{{.Names}}"
  else
    docker ps "$@"
  fi
}

enter_container() {
  [ "$#" -ne 1 ] && show_help -e enter
  docker exec -it $1 /bin/bash
}

clean_docker() {
  docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
  docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
}

docker_compose() {
  $DOCKER_COMPOSE "$@"
}

restart_container() {
  [ "$#" -ne 1 ] && show_help -e restart-container
  $DOCKER_COMPOSE restart $1
}

update_containers() {
  echo "Updating containers."
  $DOCKER_COMPOSE pull
  echo "Use 'sudo $SCRIPTNAME restart' to ensure newest containers are running."
}

docker_log() {
  docker 
}

start_containers_dc() {
  $DOCKER_COMPOSE up
}

stop_containers_dc() {
  $DOCKER_COMPOSE down
}

restart_containers_dc() {
  $DOCKER_COMPOSE restart
}

mark_loaded docker

