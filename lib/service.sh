## Service functions.

[ -z "$CTRLIB_INIT" ] && echo "Container init not loaded." && exit 100

need_conf CTRLIB_SERVICE_NAME

register_command 'logs' 'read_logs' 1 "View service logs." "[-f]\nOptions:\n  -f   Follow the logs."

register_systemctl_commands() {
  register_command 'start' 'start_containers_sc' 1 "Start the $CTRLIB_SERVICE_NAME containers."
  register_command 'stop' 'stop_containers_sc' 1 "Stop the $CTRLIB_SERVICE_NAME containers."
  register_command 'restart' 'restart_containers_sc' 1 "Restart the $CTRLIB_SERVICE_NAME containers."
}

start_containers_sc() {
  systemctl start $CTRLIB_SERVICE_NAME
}

stop_containers_sc() {
  systemctl stop $CTRLIB_SERVICE_NAME
}

restart_containers_sc() {
  systemctl restart $CTRLIB_SERVICE_NAME
}

read_logs() {
  journalctl -u $CTRLIB_SERVICE_NAME "$@"
}

mark_loaded service

