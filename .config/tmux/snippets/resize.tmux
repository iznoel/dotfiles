# vim:ft=tmux:

# i3-like resize mode for tmux
# ----------------------------

set -g @backup-window-style {
  set -gF @window-active-style-backup '#{window-active-style}'
  set -gF @window-style-backup        '#{window-style}'
  set -g window-active-style bg=color017
  set -g window-style        bg=color232
}

set -g @restore-window-style {
  set -gF window-active-style '#{@window-active-style-backup}'
  set -gF window-style        '#{@window-style-backup}'
  set -gu @window-active-style-backup
  set -gu @window-style-backup
}

set -g @resize_step 1

set -g @resize-step-up {
  if -F '#{e|<:#{@resize_step},10}' {
    set -gF @resize_step '#{e|+:#{@resize_step},1}'
  }; display 'resizeing at intervals of #{@resize_step}'
}

set -g @resize-step-down {
  if -F '#{e|>:#{@resize_step},1}}' {
    set -gF @resize_step '#{e|-:#{@resize_step},1}'
  }; display 'resizeing at intervals of #{@resize_step}'
}

set -g @resize-bottom-out  "resizep -D #{@resize_step}"
set -g @resize-bottom-in   "resizep -U #{@resize_step}"
set -g @resize-right-in    "resizep -L #{@resize_step}"
set -g @resize-right-out   "resizep -R #{@resize_step}"
set -g @resize-top-in      "resizep -Dt '{up-of}' #{@resize_step}"
set -g @resize-top-out     "resizep -Ut '{up-of}' #{@resize_step}"
set -g @resize-left-out    "resizep -Rt '{left-of}' #{@resize_step}"
set -g @resize-left-in     "resizep -Lt '{left-of}' #{@resize_step}"
set -g @resize-nudge-down  "resizep -D #{@resize_step}; resizep -Dt '{up-of}' #{@resize_step}"
set -g @resize-nudge-up    "resizep -U #{@resize_step}; resizep -Ut '{up-of}' #{@resize_step}"
set -g @resize-nudge-left  "resizep -Rt '{left-of}' #{@resize_step}; resizep -R #{@resize_step}"
set -g @resize-nudge-right "resizep -Lt '{left-of}' #{@resize_step}; resizep -L #{@resize_step}"

# Main binds
bind -N 'Enter resize mode' -T prefix C-r {set key-table resize; run -C '#{@backup-window-style}'}
bind -N 'Exit resize mode'  -T resize q   {set key-table root;   run -C '#{@restore-window-style}'}
bind -N 'List resize keys'  -T resize ?   {lsk -NT resize}

# Resize step
bind -N 'Increase resize step'  -T resize \} run -C "#{@resize-step-up}"
bind -N 'Decreaase resize step' -T resize \{ run -C "#{@resize-step-down}"

# Resize
bind -N 'Resize Bottom out' -T resize j run -C "#{q:#{E:@resize-bottom-out}}"
bind -N 'Resize Bottom in'  -T resize k run -C "#{q:#{E:@resize-bottom-in}}"
bind -N 'Resize Right in'   -T resize h run -C "#{q:#{E:@resize-right-in}}"
bind -N 'Resize Right out'  -T resize l run -C "#{q:#{E:@resize-right-out}}"
bind -N 'Resize Top in'     -T resize J run -C "#{q:#{E:@resize-top-in}}"
bind -N 'Resize Top out'    -T resize K run -C "#{q:#{E:@resize-top-out}}"
bind -N 'Resize Left out'   -T resize L run -C "#{q:#{E:@resize-left-out}}"
bind -N 'Resize Left in'    -T resize H run -C "#{q:#{E:@resize-left-in}}"

# Nudge
bind -N 'Nudge Down'  -T resize m-j run -C "#{q:#{E:@resize-nudge-down}}"
bind -N 'Nudge Up'    -T resize m-k run -C "#{q:#{E:@resize-nudge-up}}"
bind -N 'Nudge Left'  -T resize m-l run -C "#{q:#{E:@resize-nudge-left}}"
bind -N 'Nudge Right' -T resize m-h run -C "#{q:#{E:@resize-nudge-right}}"

# swap pane
bind -N 'Swap Down'  -T resize c-j swapp -dt "{down-of}"
bind -N 'Swap Up'    -T resize c-k swapp -dt "{up-of}"
bind -N 'Swap Left'  -T resize c-l swapp -dt "{right-of}"
bind -N 'Swap Right' -T resize c-h swapp -dt "{left-of}"
