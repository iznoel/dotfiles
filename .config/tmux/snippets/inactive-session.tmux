# vim:ft=tmux:

# A session to drop inactive windows into
# ---------------------------------------
#
#  Incomplete, Broken since tmux 3.2a


# pane swapping (c-o)
# menu i: join a pane next to the current pane ( directionally )
# menu o: select a pain to join onto a pane
# menu n: open a new shell pane in the current pane, moving current to a session called 'inactive'
# menu f: swap current pane with a pane from 'inactive' session
bind c-o menu -T '#[range=left][ Pane Extras ]' -- \
  '-Swapping this pane' '' '' \
    '#[fg=green]>>> #[default]using hints'       s {displayp -d0 'swapp -ds %%'} \
    '#[fg=green]>>> #[default]using choose-tree' c {choose-tree  'swapp -ds %%'} \
  '-Bring pane' '' '' \
    '#[fg=blue]>>> #[default]next to this'    i {run -C '#{q:@swap_this}' } \
    '#[fg=blue]>>> #[default]next to another' o {run -C '#{q:@swap_other}'} \
  '' '-"Breaking" panes away' '' '' \
    '#[fg=red]>>> #[default]throw away' d {run -C '#{q:@throw_away}' } \
    '#[fg=red]>>> #[default]spawn new'  n {run -C '#{q:@move_away}' } \
  '' '-Bringing panes back' '' '' \
    '#[fg=red]>>> #[default]find pane'  f {run -C '#{q:@move_back}' } \

set -g @throw_away {
  if -F '#{N/s:inactive}' '' 'new -ds inactive'
  breakp -s '#{pane_id}' -t inactive:
}

set -g @move_away {
  if -F '#{N/s:inactive}' 'neww -t inactive:' 'new -ds inactive'
  swapp -s '#{pane_id}' -t inactive:
}

set -g @move_back {
  if -F '#{N/s:inactive}' {
    choose-tree -f '##{==:##S,inactive#}' 'set -F @split_start %%; run -C "#{l:#{E:@swap_this}}"'
  } {
    menu -T '#[fg=red] No inactive panes ' \
      '#[bg=red,fg=black]Press #[bold]ok#[none] to continue#[default] :)' '' ''
  }
}

set -g @delayed_run_2 {
  run -C "#{l:#{E:@swap_other_2}}"
}

set -g @swap_this {
  if -F '#{==:#{n:#{@split_start}},0}' {
    set -F @split_start '#{pane_id}'
  }
  if -F '#{n:#{@split_trg}}' {
    run -C 'swapp -ds #{split_trg} -t #{@split_start} ; set -u @split_trg'

  } {
    display -d0 ' #[fg=red]pick target '
    displayp -d0 {
      menu  -T ' Direction ' \
      left  h 'joinp -dhb -t %1 -s #{E:@split_start}' \
      down  j 'joinp -dv  -t %1 -s #{E:@split_start}' \
      up    k 'joinp -dvb -t %1 -s #{E:@split_start}' \
      right l 'joinp -dh  -t %1 -s #{E:@split_start}'
    }
  }
}

set -g @swap_other {
  set -F @split_start '#{pane_id}'
  display -d2 ' pick a pane to split '
  displayp -d0 {
    set @split_trg %%
    run -C '#{l:#{E:@swap_other_2}}'
  }
}

set -g @swap_other_2 {
  display -d0 ' pick target '
  run -C 'selectp -t #{@split_trg}'
  displayp -d0 {
    set @split_dst %%
    run -C '#{l:#{E:@swap_other_3}}'
  }
}

set -g @swap_other_3 {
  run -C 'selectp -t #{@split_dst}'
  menu  -T ' Direction ' \
    left  h 'joinp -hbt #{@split_trg} -s #{@split_dst} ; selectp -t #{@split_start} ; run -C "#{E:swap_other}"' \
    down  j 'joinp -vt  #{@split_trg} -s #{@split_dst} ; selectp -t #{@split_start} ; run -C "#{E:swap_other}"' \
    up    k 'joinp -vbt #{@split_trg} -s #{@split_dst} ; selectp -t #{@split_start} ; run -C "#{E:swap_other}"' \
    right l 'joinp -ht  #{@split_trg} -s #{@split_dst} ; selectp -t #{@split_start} ; run -C "#{E:swap_other}"'
  set -u @split_trg
  set -u @split_dst
  set -u @split_start
}

