# vim:ft=tmux:

# Reminder.  0, 232-255 (25) are all grayscale colours

set -g @cmain     color15
set -g @chint     color5
set -g @ccrit     color1
set -g @calert    color12
set -g @calertmid color33
set -g @calertlow color147

set -g status-position bottom
set -g status-justify  left
set -g mode-style      "bg=default,fg=#{@cmain}" # menues, choose-tree
set -g message-style   "bg=default,fg=#{@cmain}" # commandline

# splits window colours
set -g  pane-border-lines            heavy
set -g  pane-border-style            "bg=default,fg=color8"
set -g  pane-active-border-style     "bg=default,fg=color7"
set -gu window-active-style  # default fg/bg for the pane's contents
set -gu window-style         # default fg/bg for the pane's contents

# statusline middle section
set -g window-status-activity-style "bg=default,fg=#{@calert}"
set -g window-status-current-style  "bg=default,fg=#{@cmain}"
set -g window-status-last-style     "bg=default,fg=#{@chint}"
set -g status-style                 "bg=default,fg=color244"

set -g  status-left-length  0  # defaults to 10
set -g  status-right-length 0  # defaults to 60

set -g popup-style        "bg=color16,fg=color1"
set -g popup-border-style "bg=color16,fg=color1"
set -g popup-border-lines simple

# formats
set -g @window-format-added "\
#{?#{e|>:#{n:#{P:x}},1},#{n:#{P:x}},}\
#{?window_zoomed_flag,z,}\
#{?#{monitor-activity},A,}\
#{?#{m:*on*,#{P:#{remain-on-exit}}},r,}"
set -g @window-format-added-wrapper "#{?#{n:#{E:@window-format-added}}\
,#[fg=color239](#[default]#{E:@window-format-added}#[fg=color239]),}"

set -g window-status-separator '#[fg=color235]|'
set -g window-status-format "#I:#{?automatic-rename,#{=4:#{window_name}},#W}\
#{?window_last_flag,#[fg=#{@calertlow}],}\
#[push-default]#{E:@window-format-added-wrapper}"
set -g window-status-current-format "#I:#{window_name}\
#[fg=#{@calertmid}]#[push-default]#{E:@window-format-added-wrapper}"


# Problem...
# This is suffering from dir-trim
# TODO return N first / last segments
set -gF @HOME $HOME
set -g @pane-path '#{s/#{l:/}([^#{l:/}][^#{l:/}]?[^#{l:/}]?)[^#{l:/}]*/#{l:/}\1/:\
#{s/#{l:/}[^@sl]*$/#{l:/}/:#{s/#{l:#{@HOME}}/~/:pane_current_path}}}\
#{s/.*#{l:/}//:#{pane_current_path}}'

set -g pane-border-format "(:#{E:@pane-path}\
:#{?pane_active,#[fg=#{@chint}],}#{pane_pid}\
#{?#{==:#{remain-on-exit},on},#[default]\
:#{?pane_active,#[fg=#{@chint}],}r,}\
#[default]:)"

set -g @is_zoomed "#{?window_zoomed_flag,#[fg=#{@calertmid}][Z]#[default] ,}"
set -g @key_table "#{?#{!=:#{client_key_table},root},#[fg=#{@calertmid}][#{client_key_table}]#[default] ,}"

set -g @time '#[fg=white,bold]%a, %b %d %R'
set -g @weechat_alert '#{S:#{?#{N/w:weechat},#{W:#{P:#{?#{==:weechat,\
#{pane_current_command}},#{?m:*#,#I##*,#,#{session_alerts}},}}},}}'

set -g status-left  "#[fg=white,bold]#{session_name}#[default]) "
set -g status-right "#{E:@weechat_alert}#{search_match} #{E:@key_table}#{E:@is_zoomed}#{E:@time}"
