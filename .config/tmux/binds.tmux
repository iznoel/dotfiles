# vim:fdm=marker:ft=tmux:

unbind [  # copy-mode
unbind ]  # paste-buffer -p
unbind -  # delete-buffer
unbind \; # last-pane
unbind -T root WheelUpPane

bind -N 'Open a URL'        C-u if -b tmux-pick-url '' ''
bind -N 'Reload configs'      R {source "~/.config/tmux/tmux.conf"; display -d700 "Configs reloaded" }
bind -N 'New window in cwd'   c new-window -c '#{pane_current_path}'
bind -N 'Toggle status'       g set status
bind -N 'Toggle Pane Status ' G set pane-border-status

bind -N 'Last window'    l last
bind -N 'Last pane'    m-l lastp -Z
bind -N 'Last session'   L switchc -l

bind -N 'select previous window' p previous-window
bind -N 'select next window'     n next-window

bind -N  'selectp <' c-h   selectp -L
bind -N  'selectp v' c-j   selectp -D
bind -N  'selectp ^' c-k   selectp -U
bind -N  'selectp >' c-l   selectp -R

bind -rN 'swapp <'   C-M-h swapp -t '{left-of}'
bind -rN 'swapp v'   C-M-j swapp -t '{down-of}'
bind -rN 'swapp >'   C-M-k swapp -t '{up-of}'
bind -rN 'swapp ^'   C-M-l swapp -t '{right-of}'
bind -N  'swap hint' C-q   displayp -d0 "swapp -ds '%%'"

source "~/.config/tmux/snippets/resize.tmux"

bind -N 'find pane by title / current command' c-f {
  command-prompt -p '#[fg=red]Find pane by title:#[default]' {
  run -C "menu -x0 -yS -T '[ Matches for #[fg=red]%1#[default] ]' --\
  #{S:#{W:#{P:#{?#{||:#{m:*%1*,#{pane_title}},#{m:*%1*,#{pane_current_command}}},\
  '#[reverse]#{p17:#{=/-14/..:  #{session_name}:#{window_index}.#{pane_index}}}#[default]\
 #{p20:#{pane_current_command}} #[reverse] #{s/#{l:$HOME}/~/:#{pane_current_path}}\
 ' '' 'switch-client -t #{pane_id}',}}}}"
  }
}

# prefix passthrough
# ------------------

set -g @passthrough off
set -g prefix c-a
bind -T prefix c-a send c-a

bind -N 'passthrough mode' F1 {
  set prefix NONE
  set key-table NONE
  set @passthrough on
}

bind -N 'exit passthrough mode' -T NONE C-F1 {
  set prefix c-a
  set key-table root
  set @passthrough off
}

# copy mode
# ---------

bind C-c copy-mode
bind C-v choose-buffer
bind -T copy-mode-vi v     send-keys -X begin-selection
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -sel clip -i"
bind -T copy-mode-vi y     send-keys -X copy-pipe-and-cancel "~/.config/tmux/yank.sh"

# window splitting
# ----------------

bind -N 'split pane' \\ menu -T \
'[ #[fg=blue]split window#[default] ]' \
    left      h 'splitw -hb  -c "#{pane_current_path}"' \
    right     l 'splitw -h   -c "#{pane_current_path}"' \
    up        k 'splitw -vb  -c "#{pane_current_path}"' \
    down      j 'splitw -v   -c "#{pane_current_path}"' \
    '' \
    leftmost  H 'splitw -hfb -c "#{pane_current_path}"' \
    rightmost L 'splitw -hf  -c "#{pane_current_path}"' \
    top       K 'splitw -vfb -c "#{pane_current_path}"' \
    bottom    J 'splitw -vf  -c "#{pane_current_path}"'

# custom menues
# -------------

bind -N 'Menu for panes' C-p menu -T '[ #[fg=blue]pane macros#[default] ]' \
  'remain on exit' r {if -F '#{pane_dead}' 'respawn-pane' 'set -p remain-on-exit'} \
  'break pane'     d {breakp -d} \
  '(obtain) pane'  o {choose-tree 'joinp -t %%'} \
  ' (swap) pane'   s {choose-tree 'swapp -s %%'} \
  'show colors'    c {popup -E -h100% -xR 'bash 255colo | less -AR'}

bind -N 'Menu for windows' C-w menu -T '[ #[fg=blue]window operations#[default] ]' \
  'New window'           n new-window \
  'New window (named)'   N {command-prompt -p 'window name:' 'new-window -n "%%"'} \
  '' \
  'Monitor activity'     m {set -w monitor-activity} \
  'Swap window'          s {choose-tree -wf '##{==:##{session_name},#{session_name}}' 'swap-window -s %%'} \
  'Obtain window'        o {choose-tree -wf '##{!=:##{session_name},#{session_name}}' 'move-window -s %%'} \
  'Rename window'        r {
    if -F '#{==:#{automatic-rename},1}' \
    {command-prompt -I '#{window_name}' 'rename-window -- "%%"'} \
    {set -w automatic-rename on}}\
  'refit window'         f {command-prompt -I1 -p 'Fit after winnr:' 'if "ii=%1; until tmux movew -s #I -t \$(( ii++ )); do :;done; unset ii" "" ""'} \
  'Pick Window'        c-w {run -C "#{l:#{E:@menu_session_windows}}"}

set -g @session_menu_basic "\
  'new session'          n new-session \
  'new session (named)'  N \"command-prompt -p 'session name:,window name:' 'new-session -s \\"%1\\" #{?#{n:%2}?-n \\"%2\\",}'\"\
  'rename session'       r \"command-prompt -I '#S' 'rename-session -- \\"%%\\"'\" \
"

set -g @session_menu "display-menu -T '[ #[fg=blue]Session Menu#[default] ]'"
bind -N 'Menu for sessions' C-s run -C "#{@session_menu} #{@session_menu_basic}"
bind -N 'Menu for sessions' -T root MouseDown3StatusLeft run -C '#{@session_menu} -x M -y W
  #{@session_menu_basic} \
  "" "-Windows in session" "" "" \
  #{E:#{W: "#{E:window-status-format}" "#I" "select-window -t #I" }}\
  "> last"   "!"  "select-window -t   !" \
  "> marked" "\~" "select-window -t \\~" \
'

