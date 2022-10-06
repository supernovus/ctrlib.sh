## Service functions.

[ -z "$CTRLIB_LIB_DIR" ] && echo "Container init not loaded." && exit 100

[ -z "$CTRLIB_SERVICE_NAME" ] && no_conf CTRLIB_SERVICE_NAME

register_command 'exam' 'example_app_command' 1 "Run example"

example_app_command() {
  echo "This doesn't really do anything, but is an example..."
}

mark_loaded example

