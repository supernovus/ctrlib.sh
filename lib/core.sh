#$< ctrlib::core
# Control script library core

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::var -P CTRLIB_ -a CMD_LIST

lum::use lum::user lum::themes::default lum::help::list

lum::fn::alias::group CMD 1 CTRLIB_CMD_LIST

lum::help::register

lum::fn ctrlib::usage 0 -a $SCRIPTNAME 1 0 -a --usage 0 0
#$ <<command>> `{...}`
#
#Commands:
#
ctrlib::usage() {
  echo -n "Usage: "
  lum::help ctrlib::usage
  lum::help::list CTRLIB_CMD_LIST
  lum::help::moreinfo
  exit 1
}
