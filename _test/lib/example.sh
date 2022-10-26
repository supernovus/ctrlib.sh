## Service functions.

[ -z "$CTRLIB_INIT" ] && echo "Container init not loaded." && exit 100

need docker

register_command 'exam' 'example_app_command' 1 "Run example"
register_command 'cname' 'get_container' 1 "Get container id" "<name>\n If the name is an alias shows the real name"
register_list_container_aliases 'aliases'

example_app_command() {
  echo "This doesn't really do anything, but is an example..."
}

mark_loaded example
