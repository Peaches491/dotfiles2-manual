
function _ignore_file_regex {
  echo "\
  --exclude .*~ \
  --exclude ${INORUN_EXCLUDE:-.git} \
  --exclude .git \
  --exclude .ros \
  --exclude .sw. \
  --exclude 4913$ \
  --exclude target \
  --exclude index.lock"
}

function _do {
  "$@"
  echo "Exited: $?"
  echo ""
}

function _inotifyrun {
  # Using do-while loop
  while : ; do
    _do "$@"
    inotifywait -qre close_write --format "$FORMAT" \
      $(_ignore_file_regex) . || break
  done
}

function _fswatch {
  _do "$@"
  echo "Waiting for next change..."
  fswatch $(_ignore_file_regex) --recursive --print0 ./ | while read -d "" event; do
    echo -e "\033[1;33m$event\033[0m written"
    _do "$@"
  done
}

function inotifyrun {
  FORMAT=$(echo -e "\033[1;33m%w%f\033[0m written")

  #set -x
  case $OSTYPE in
    darwin*) # Mac OSX
      echo "Mac OSX"
      _fswatch "$@"
      ;;
    linux*) # Linux
      echo "Linux"
      _inotifyrun "$@"
      ;;
    msys*) # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
      echo "Windows"
      _fswatch "$@"
      ;;
    cygwin*) # POSIX compatibility layer and Linux environment emulation for Windows
      echo "Cygwin"
      _fswatch "$@"
      ;;
    solaris*)
      echo "Solaris"
      _fswatch "$@"
      ;;
    bsd*)
      echo "FreeBSD"
      _fswatch "$@"
      ;;
    *)
      echo "Unknown OS \"$OSTYPE\""
      echo "Defaulting to fswatch..."
      _fswatch "$@"
      ;;
  esac

  #set +x
}
