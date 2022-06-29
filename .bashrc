#!/bin/bash
# vim:ts=2:sts=2:sw=2:et:fdm=marker:

# shellcheck disable=SC1090
# shellcheck disable=SC2016

#   ~/.inputrc
#   ~/.bash_profile
#   ~/.config/aliasrc
if [[ $- != *i* ]]; then
  return
elif [[ -n $SSH_TTY && -z $TMUX ]]; then
  exec tmux
fi

stty erase ^?

for rc in ~/{.config/aliasrc,bin/{prompt,bashjobs,wttr}}; do
  [[ -f "$rc" ]] && source "$rc"
done

shopt -s histappend
shopt -s nocaseglob globstar extglob # nullglob
shopt -s autocd cdspell dirspell
shopt -s checkjobs
shopt -s histverify

unset HISTSIZE HISTFILESIZE
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="&:?:??:???:exit*:pwd*:clear*:ls*:pass*:todo*"

# Thank you Kai Hendry!
if [[ -d ~/.bash_history.d ]] \
  || mkdir ~/.bash_history.d &>/dev/null \
  || echo "Failed to create .bash_history.d" >&2; then
  printf -v HISTFILE "%s/.bash_history.d/%(%Y-%m)T" ~ $EPOCHSECONDS
fi

bind -x '"\C-xt": nvim +10000000 ~/todo'
bind -x '"\C-xd": tput smcup reset; pit edit; tput rmcup'
bind -x '"\C-xj": jobs"'
if declare -f showjobs &>/dev/null; then
  bind -x '"\C-xj": showjobs '
fi

if declare -f tcd &>/dev/null; then
  bind -x '"\C-xc":tcd && { "${PROMPT_COMMAND[@]}"; echo -en "\r${PS1@P}"; }'
fi

# if [[ -z $SSH_TTY$VIMRUNTIME ]]; then
#   banner
# fi
