#$< ctrlib::service
# systemd related functions

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::var::need CTRLIB_SERVICE_NAME
lum::use ctrlib::core

lum::fn ctrlib::service::register 4
#$ - Register start, stop, and restart commands using systemctl
ctrlib::service::register() {
  local hide="${1:-0}"
  lum::fn::alias ctrlib::service::start start CMD
  lum::fn::alias ctrlib::service::stop stop CMD
  lum::fn::alias ctrlib::service::restart restart CMD
  lum::fn::alias ctrlib::service::logs logs CMD
}

lum::fn ctrlib::service::start 4 -a start-service 0 0
#$ - Start the service
ctrlib::service::start() {
  systemctl start $CTRLIB_SERVICE_NAME
}

lum::fn ctrlib::service::stop 4 -a stop-service 0 0
#$ - Stop the service
ctrlib::service::stop() {
  systemctl stop $CTRLIB_SERVICE_NAME
}

lum::fn ctrlib::service::restart 4 -a restart-service 0 0
#$ - Restart the service
ctrlib::service::restart() {
  systemctl restart $CTRLIB_SERVICE_NAME
}

lum::fn ctrlib::service::logs 0 -a service-logs 0 0
#$ [[-f]]
#
# Get service logs
#
# ((-f))      Follow logs
#
ctrlib::service::logs() {
  journalctl -u $CTRLIB_SERVICE_NAME "$@"
}
