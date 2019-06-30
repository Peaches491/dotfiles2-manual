# If not running interactively, don't do anything.
case $- in
  *i*) ;;
  *) return ;;
esac

# Extra config files
source ~/.commonrc
source_files_in_directory ~/.config/bashrc.d

# Update LINES and COLUMNS after each command.
shopt -s checkwinsize

# "**" recursively expands directories.
# Older versions of bash don't have this option, so we can ignore errors.
shopt -s globstar 2>/dev/null

# Allow <C-s> to pass through the terminal instead of stopping it.
[[ $- == *i* ]] && stty stop undef

# allow tab-completion while using sudo
complete -cf sudo

# Append to history file instead of overwriting.
shopt -s histappend

# Ignore immedately repeated commands and ignore commands prefixed with spaces.
export HISTCONTROL=ignoreboth

function git_prompt {
  local down_arrow_symbol=$'\xe2\x86\x93'
  local right_arrow_symbol=$'\xe2\x86\x92'
  local up_arrow_symbol=$'\xe2\x86\x91'
  local left_arrow_symbol=$'\xe2\x86\x90'
  local check_symbol="✓"
  local x_symbol="✗"

  local stat="$(git status -bs --porcelain --ignore-submodules)"
  local status_first_line="$(head -n1 <<< "$stat")"

  local ref="$(git symbolic-ref HEAD)"
  local branch="${ref#refs/heads/}"
  local change="$(git rev-parse --short HEAD)"

  local ahead=""
  local behind=""
  local ahead_re=".+ahead ([0-9]+).+"
  local behind_re=".+behind ([0-9]+).+"
  [[ "$status_first_line" =~ "$ahead_re" ]] && ahead="$BASH_REMATCH[1]"
  [[ "$status_first_line" =~ "$behind_re" ]] && behind="$BASH_REMATCH[1]"

  local upstream_remote=""
  local upstream_branch=""
  local upstream_re=".+\.\.\.([[:print:]]+)/([^[:space:]]+)"
  [[ "$status_first_line" =~ "$upstream_re" ]] && upstream_remote="$BASH_REMATCH[1]" && upstream_branch="$BASH_REMATCH[2]"

  local stash_count="$(git stash list 2> /dev/null | wc -l | tr -d ' ')"
  local staged_count="$(tail -n +2 <<< "$stat" | grep -v '^[[:space:]?]'  | wc -l | tr -d ' ')"
  local unstaged_count="$(tail -n +2 <<< "$stat" | grep '^.[^[:space:]?]'  | wc -l | tr -d ' ')"
  local untracked_count="$(tail -n +2 <<< "$stat" | grep '^??'  | wc -l | tr -d ' ')"

  local prompt=""
  if [ -z $branch ]; then
    prompt="$fg_green$change"
  else
    prompt="$fg_green$branch"
    if [ -z $upstream_remote ]; then
      prompt="$prompt$fg_cyan(~)"
    elif [ "$upstream_branch" == "$branch" ]; then
      prompt="$prompt$fg_cyan($upstream_remote)"
    else
      prompt="$prompt$fg_cyan($upstream_remote/$upstream_branch)"
    fi
    prompt="$prompt$reset_color:$fg_magenta$change"
  fi

  local dirty_symbol="$fg_red$x_symbol"
  local clean_symbol="$fg_green$check_symbol"

  if [[ $staged_count -gt 0 || $unstaged_count -gt 0 || $untracked_count -gt 0 ]]; then
    prompt="$prompt $fg_red("
    [[ "$staged_count" -gt 0 ]] && prompt="$prompt$fg_green+"
    [[ "$unstaged_count" -gt 0 ]] && prompt="$prompt$pfg_red*"
    [[ "$untracked_count" -gt 0 ]] && prompt="$prompt$fg_cyan?"
    prompt="$prompt$fg_red)"
  else
    prompt="$prompt $clean_symbol"
  fi
  [[ $behind -gt 0 ]] && prompt="$prompt $fg_red$down_arrow_symbol$behind"
  [[ $ahead -gt 0 && $behind -eq 0 ]] && prompt="$prompt$fg_cyan"
  [[ $ahead -gt 0 ]] && prompt="$prompt $up_arrow_symbol$ahead"
  [[ $stash_count -gt 0 ]] && prompt="$prompt $fg_yellow(stash: $stash_count)"

  echo "$prompt"
}

function build_ps1() {
  local exit_status="$?"

  local reset_color=$'\e[0m'
  local fg_black=$'\e[0;30m'
  local fg_red=$'\e[0;31m'
  local fg_green=$'\e[0;32m'
  local fg_yellow=$'\e[0;33m'
  local fg_blue=$'\e[0;34m'
  local fg_magenta=$'\e[0;35m'
  local fg_cyan=$'\e[0;36m'
  local fg_white=$'\e[0;37m'

  local fg_bold_white=$'\e[1;37m'
  local bg_red=$'\e[41m'

  local ps1_user=$'\u'
  local ps1_host=$'\H'
  local ps1_pwd=$'\w'
  local ps1_date=$'\D{%Y/%m/%d}'
  local ps1_time=$'\D{%H:%M:%S}'
  local ps1_priv=$'\$'

  local ps1=''

  # Exit code alert
  if [[ $exit_status != 0 ]]; then
    ps1="$ps1$fg_bold_white$bg_red!!! Exited: $exit_status !!!\n"
  fi
  ps1="$ps1\n"

  # venv prompt
  if [ "$VIRTUAL_ENV" ]; then
    ps1="$ps1$fg_green|$fg_whitevenv $fg_blue$VIRTUAL_ENV$fg_green|"
  fi

  # Git prompt
  if which git &> /dev/null && [[ -n "$(git rev-parse HEAD 2> /dev/null)" ]]; then
    ps1="$ps1$fg_green|$(git_prompt)$fg_green|\n"
  fi

  ps1="$ps1$fg_yellow$ps1_user"
  ps1="$ps1$fg_white@"
  ps1="$ps1$fg_green$ps1_host "
  ps1="$ps1$fg_blue[$ps1_pwd] "
  ps1="$ps1$fg_magenta$ps1_date "
  ps1="$ps1$fg_cyan$ps1_time "

  ps1="$ps1\n"
  ps1="$ps1$fg_white $ps1_priv$reset_color "

  export PS1="$ps1"
}

declare PROMPT_COMMAND="build_ps1"
#export PS1="$(build_ps1)"

export HISTFILE=~/.history.bash
