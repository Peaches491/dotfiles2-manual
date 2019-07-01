complete -F _fzf_path_completion -o default -o bashdefault e
_fzf_compgen_path() {
command find -L "$1" \
  -name .git -prune -o -name .svn -prune -o \
  -type d -name 'third_party' -prune -o \
  -type d -name 'bazel-*' -prune -o \
  \( -type d -o -type f -o -type l \) \
  -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
}

_fzf_compgen_dir() {
command find -L "$1" \
  -name .git -prune -o -name .svn -prune \
  -type d -name 'third_party' -prune -o \
  -type d -name 'bazel-*' -prune -o \
  -type d \
  -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
}

