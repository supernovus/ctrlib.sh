## Default set of libraries for control scripts.

[ -z "$CTRLIB_INIT" ] && echo "Container init not loaded." && exit 100

use_lib docker web
use_user_libs

