## ctrlib::core

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

declare -gr CTRLIB_LIB_DIR=`dirname $BASH_SOURCE`
declare -gr CTRLIB_VER=2.0.0
declare -ga CTRLIB_CMD_LIST
declare -gi CTRLIB_DEBUG=0

lum::lib ctrlib::core $CTRLIB_VER

lum::use lum::tmpl lum::user lum::themes::default

lum::fn::alias::group CMD 1 CTRLIB_CMD_LIST

lum::fn::alias lum::help help 1
lum::fn::alias lum::help --help

lum::fn ctrlib::usage 0 -t 0 31 -a $SCRIPTNAME 1 0 -a --usage 0 0
#$ <<command>> `{...}`
#
#Commands:
#@>lum::tmpl;
#{{ctrlib::usage::list}}
#
#{{lum::help::moreinfo}}
#
ctrlib::usage() {
  echo -n "Usage: "
  lum::help ctrlib::usage
  exit 1
}

lum::fn ctrlib::usage::list 0 -a commands 1 0 -a --commands 0 0
#$ `{--}`
#
# Show a list of CLI commands.
#
ctrlib::usage::list() {
  lum::help::list CTRLIB_CMD_LIST 20 "-" " '" "'"
}

lum::fn ctrlib::debug 
#$ <<minval>> [[message...]]
#
# Handle ctrlib specific debug messages.
#
# See ``lum::var::debug`` for the description of the parameters.
#
ctrlib::debug() {
  [ $# -lt 1 ] && lum::help::usage
  lum::var::debug CTRLIB_DEBUG "$@"
}
