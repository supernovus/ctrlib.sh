## The bootstrap library for all ctrlib scripts.

[ -z "$BASH_VERSION" ] && echo "Must use bash" && exit 150

BASHVER=`echo $BASH_VERSION | awk -F. '{print $1}'`

[ "$BASHVER" -lt 4 ] && echo "Bash version 4 or higher required." && exit 150

[ -z "$BASH_SOURCE" ] && echo "Must source init.sh" && exit 101

[ -z "$CTRLIB_LIB_DIR" ] && CTRLIB_LIB_DIR=`dirname $BASH_SOURCE`

[ -z "$CTRLIB_USER_DIR" ] && CTRLIB_USER_DIR=".ctrlib"

SCRIPTNAME=`basename $0`

no_conf() {
  echo "Missing $1 variable in $SCRIPTNAME script."
  exit 199
}

need_conf() {
  [ -z "${!1}" ] && no_conf "$1"
}

debug() {
  [ "x$CTRLIB_DEBUG" = "x1" ] && echo "$@"
}

declare -a CTRLIB_APP_LIB_DIRS
declare -a CTRLIB_APP_CONF_DIRS
declare -a CTRLIB_CMD_LIST
declare -A CTRLIB_CMD_METHODS
declare -A CTRLIB_CMD_DESC
declare -A CTRLIB_CMD_HELP
declare -A CTRLIB_CMD_HELPFUNC
declare -A CTRLIB_LOADED_LIBS

#declare -A CTRLIB_DALIAS

no_lib() {
  echo "The $1 library is not loaded in $SCRIPTNAME script."
  exit 198
}

need() {
  [ -z "${CTRLIB_LOADED_LIBS[$1]}" ] && no_lib "$1"
}

register_command() {
  [ $# -lt 3 ] && echo "register_command <command> <function> <list> [desc] [help]" && exit 190
  CTRLIB_CMD_METHODS[$1]=$2
  [ $3 -eq 1 ] && CTRLIB_CMD_LIST+=($1)
  [ $# -gt 3 ] && register_desc "$2" "$4"
  [ $# -gt 4 ] && register_help "$2" "$5"
}

register_desc() {
  [ $# -ne 2 ] && echo "register_desc <function> <usage> -- $@" && exit 189
  CTRLIB_CMD_DESC[$1]=$2
}

register_help() {
  [ $# -ne 2 ] && echo "register_help <function> <help>" && exit 188
  CTRLIB_CMD_HELP[$1]=$2
}

register_help_func() {
  [ $# -ne 2 ] && echo "register_help_func <target_func> <help_func>" && exit 187
  CTRLIB_CMD_HELPFUNC[$1]=$2
}

register_command 'help' 'show_help' 0

mark_loaded() {
  CTRLIB_LOADED_LIBS[$1]=1
}

usage() {
  local K CN C U
  echo "Usage: sudo $SCRIPTNAME <command> [params...]"
  echo
  echo "Commands:"
  echo
  for K in "${CTRLIB_CMD_LIST[@]}"; do
    CN="${CTRLIB_CMD_METHODS[$K]}"    
    C=`printf '%-20s' "'$K'"`
    U=${CTRLIB_CMD_DESC[$CN]}
    echo " $C $U"
  done
  echo
  echo "Use the special command 'help <command>' for more help on a command."
  echo
  exit 1
}

show_help() {
  local CN RETCODE=0 CL=

  [ "$1" = "-e" ] && RETCODE=1 && shift
  [ "$1" = "-c" ] && CL=$2 && shift && shift
  [ -z "$1" ] && usage
  [ -z "$CL" ] && CL=$1
  if [ -n "${CTRLIB_CMD_METHODS[$1]}" ]; then
    CN="${CTRLIB_CMD_METHODS[$1]}"
  else
    CN=$1
  fi
  if [ -n "${CTRLIB_CMD_HELPFUNC[$CN]}" ]; then
    ${CTRLIB_CMD_HELPFUNC[$CN]} "$@"
  elif [ -n "${CTRLIB_CMD_HELP[$CN]}" ]; then
    [ -n "${CTRLIB_CMD_DESC[$CN]}" ] && echo "${CTRLIB_CMD_DESC[$CN]}"
    echo -e "Usage: $CL ${CTRLIB_CMD_HELP[$CN]}"
  else
    echo "No help for '$CL' command."
  fi
  exit $RETCODE
}

parse_commands() {
  [ $# -lt 1 ] && usage
  local MAINCMD="$1"
  shift
  if [ -n "${CTRLIB_CMD_METHODS[$MAINCMD]}" ]; then
    ${CTRLIB_CMD_METHODS[$MAINCMD]} "$@"
  else
    echo "Unrecognized command '$MAINCMD' specified."
    usage
  fi
}

find_source() {
  [ $# -lt 2 ] && echo "find_source <filename> <dir1> [dir2] ..." && exit 221
  local tryfile AD AF="$1"
  shift
  #echo "looking for $AF" >&2
  for AD in "$@"; do
    [ ! -d "$AD" ] && continue
    tryfile="$AD/$AF"
    [ -f "$tryfile" ] && echo "$tryfile" && return 0
  done
  return 1
}

## Use one or more libraries and/or config files.
##
## Each argument is the name of an item you want to use,
## or one of the special options:
##
## --need   Following items are mandatory.
## --opt    Following items are optional.
## --conf   Following items are config files.
## --lib    Following items are library files.
##
## Default options are as if --need --lib was passed.
##
use_lib() {
  local libFile isFatal=1 useConf=0
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "--need" ]; then
      isFatal=1
    elif [ "$1" = "--opt" ]; then 
      isFatal=0
    elif [ "$1" = "--conf" ]; then
      useConf=1
    elif [ "$1" = "--lib" ]; then 
      useConf=0
    else
      if [ $useConf -eq 1 ]; then
        libFile="$(find_source $1.conf ${CTRLIB_APP_CONF_DIRS[@]})"
      else
        libFile="$(find_source $1.sh ${CTRLIB_APP_LIB_DIRS[@]})"
      fi

      if [ -f "$libFile" ]; then 
        . "$libFile"
      elif [ $isFatal -eq 1 ]; then
        echo "Could not find $1 library."
        exit 222
      fi
    fi
    shift
  done
}

## Add an app-specific library directory.
##
## By default we only include the main ctrlib libraries.
use_app_libs() {
  [ $# -ne 1 ] && echo "use_app_libs <path_to_app_libs>" && exit 186
  [ ! -d "$1" ] && echo "use_app_libs: '$1' is not a valid path" && exit 185
  CTRLIB_APP_LIB_DIRS+=($1)
}

## The default lib dir.
use_app_libs $CTRLIB_LIB_DIR

## Add an app-specific config directory.
##
## Config files are literally the same as libraries, 
## but have a '.conf' file extension instead of '.sh'.
##
use_app_conf() {
  [ $# -ne 1 ] && echo "use_app_conf <path_to_app_conf>" && exit 186
  [ ! -d "$1" ] && echo "use_app_conf: '$1' is not a valid path" && exit 185
  CTRLIB_APP_CONF_DIRS+=($1)
}

## Not the same as $HOME; this works with sudo.
get_home_dir() {
  which getent >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo $(getent passwd $(logname) | cut -d: -f6)
  else
    echo $(grep "$(logname):x:" /etc/passwd | cut -d: -f6)
  fi
}

## The path where our custom settings can be saved
get_user_config_dir() {
  local HOMEDIR="$(get_home_dir)"
  echo "$HOMEDIR/$CTRLIB_USER_DIR"
}

## Enable user libraries by adding '.lib' files to the config dir(s).
## First we look in the main config dir, and then in a script-specific sub-dir.
use_user_libs() {
  local USERLIBS="$(get_user_config_dir)"
  use_libs_from "$USERLIBS"
  use_libs_from "$USERLIBS/$SCRIPTNAME"
}

## Get a list of libraries to allow.
use_libs_from() {
  local LIBNAME
  if [ -d "$1" ]; then
    for LIBNAME in $1/*.lib; do
      [ -e "$LIBNAME" ] || continue
      LIBNAME=$(basename $LIBNAME .lib)
      use_lib $LIBNAME
    done
  fi
}

# A helper for making a copy of an original function.
copy_function() {
  test -n "$(declare -f "$1")" || return 
  eval "${_/$1/$2}"
}

CTRLIB_INIT=1
