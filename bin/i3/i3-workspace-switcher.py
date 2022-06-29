#!/usr/bin/env python3

from i3ipc import Connection, Event, events
from functools import reduce
from collections.abc import Callable
import fcntl

"""
Example config
--------------

bindsym $mod+1 nop workspace number 1  or cycle
bindsym $mod+2 nop workspace number 2  or cycle
bindsym $mod+3 nop workspace number 3  or cycle
bindsym $mod+4 nop workspace number 4  or cycle
bindsym $mod+5 nop workspace number 5  or cycle
bindsym $mod+6 nop workspace number 6  or cycle
bindsym $mod+7 nop workspace number 7  or cycle
bindsym $mod+8 nop workspace number 8  or cycle
bindsym $mod+9 nop workspace number 9  or cycle
bindsym $mod+0 nop workspace number 10 or cycle

exec_always --no-startup-id i3-smarter-workspace.py
"""

class ws_switcher:
    def __init__(self, conn: Connection,
            lock: Callable[[str], object]):
        self.locked = lock(f"{conn.socket_path}.ws-switcher.lock")
        self.ws = reduce(lambda a, v: v.num if v.focused else a,
            conn.get_workspaces(), 0)
        self.cycling = self.ws
        conn.on(Event.BINDING, self.route_bind)

    def route_bind(self, ipc: Connection, event: events.BindingEvent):
        bind = event.binding.command
        if bind.startswith('nop'):
            instruction = tuple(filter(len, bind.split(' ')))[1:]
            match instruction:
                case 'workspace', 'number', nr, 'or', 'cycle':
                    self.on_cycle_window(ipc, int(nr))
                case 'workspace', 'number', nr, 'or', 'cycle', 'window':
                    self.on_cycle_window(ipc, int(nr))
                case 'workspace', 'number', nr, 'or', 'cycle', 'workspace':
                    self.on_cycle_workspace(ipc, int(nr))

    def on_cycle_workspace(self, ipc: Connection, ws: int):
        if self.cycling == ws:
            ipc.command('workspace next')
        else:
            self.to_workspace(ipc, ws)
            self.cycling = ws

    def on_cycle_window(self, ipc: Connection, ws: int):
        if not self.to_workspace(ipc, ws):
            windows = [con
                for output in ipc.get_tree()   if output.name != '__i3'
                for ws     in output.nodes     if ws.num      == self.ws
                for con    in ws.descendants() if con.window]
            if len(windows) > 1:
                next = reduce(lambda a, v: v[1].id if windows[v[0]-1].focused
                        else a, enumerate(windows), 0)
                ipc.command(f'[con_id={next}] focus')

    def to_workspace(self, ipc: Connection, ws: int):
        if self.ws != ws:
            ipc.command(f'workspace number {ws}')
            self.ws = ws
            return True


def flock(fname: str):
    fd = open(fname, 'w')
    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    return fd


if __name__ == "__main__":
    i3conn = Connection()
    ws_switcher(conn=i3conn, lock=flock)
    i3conn.on(Event.SHUTDOWN, lambda _: exit(0) )
    i3conn.main()
