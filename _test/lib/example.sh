## Example functions.

[ -z "$LUM_CORE" ] && echo "lum::core not loaded" && exit 100

lum::use docker

lum::lib ctrlib::test::example $CTRLIB_VER

lum::fn ctrlib::test::example::command 0 -a exam 1 CTRLIB_CMD_LIST
#$ 
#
# An example that doesn't really do anything
#
example_app_command() {
  echo "This doesn't really do anything, but is an example..."
}

lum::fn::alias ctrlib::docker::get cname
ctrlib::docker::registerListAlias aliases 
