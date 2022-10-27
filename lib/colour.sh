## A helper for setting colours.

clr() {
  local target=fg output
  local -A colours 
  colours[fg]=-1
  colours[bg]=-1
  colours[bold]=0

  for arg in $@
  do 
    case "$arg" in
      fg)
        target=fg
      ;;
      bg)
        target=bg
      ;;
      light|bold|bright)
        colours[bold]=1
      ;;
      dark|unbold|thin)
        colors[bold]=0
      ;;
      black)
        colours[$target]=0
      ;;
      white)
        colours[$target]=7
      ;;
      blue)
        colours[$target]=4
      ;;
      green)
        colours[$target]=2
      ;;
      cyan)
        colours[$target]=6
      ;;
      red)
        colours[$target]=1
      ;;
      purple)
        colours[$target]=5
      ;;
      yellow)
        colours[$target]=3
      ;;
      end|normal|reset|plain)
        echo -e "\033[00m"
        return
      ;;
    esac
  shift 
  done
  output="${colours[bold]}";
  [ "${colours[fg]}" -ne -1 ] && output="$output;3${colours[fg]}"
  [ "${colours[bg]}" -ne -1 ] && output="$output;4${colours[bg]}"
  echo -e "\033[${output}m"
}
