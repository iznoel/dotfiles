#!/usr/bin/env python3

from i3ipc import Connection, Event, events
from functools import reduce
from typing import Callable
import os, fcntl

"""
Example config
--------------

bindsym $mod+1 nop workspace num 1  or cycle
bindsym $mod+2 nop workspace num 2  or cycle
bindsym $mod+3 nop workspace num 3  or cycle
bindsym $mod+4 nop workspace num 4  or cycle
bindsym $mod+5 nop workspace num 5  or cycle
bindsym $mod+6 nop workspace num 6  or cycle
bindsym $mod+7 nop workspace num 7  or cycle
bindsym $mod+8 nop workspace num 8  or cycle
bindsym $mod+9 nop workspace num 9  or cycle
bindsym $mod+0 nop workspace num 10 or cycle

exec_always --no-startup-id i3-smarter-workspace.py
"""

class ws_switcher:
    def __init__(self, conn: Connection, lock: Callable):
        self.locked = lock(f"{conn.socket_path}.ws-switcher.lock")
        self.ws = reduce(lambda a, v: v.num if v.focused else a,
            conn.get_workspaces(), 0)
        conn.on(Event.BINDING, self.route_bind)
        conn.on(Event.WORKSPACE_FOCUS, self.on_ws_change)

    def on_ws_change(self, ipc: Connection, event: events.WorkspaceEvent):
        self.ws = event.ipc_data['current']['num']

    def route_bind(self, ipc: Connection, event: events.BindingEvent):
        bind = event.ipc_data['binding']['command']
        if bind.startswith('nop'):
            instruction = tuple(filter(len, bind.split(' ')))[1:]
            match instruction:
                case 'workspace', 'number' | 'num', nr, 'or', 'cycle':
                    return self.to_workspace(ipc, int(nr))

    def to_workspace(self, ipc: Connection, ws: int):
        if self.ws != ws:
            return ipc.command(fr'workspace number {ws}')
        windows = [con
            for output in ipc.get_tree()   if output.name != '__i3'
            for ws     in output.nodes     if ws.num      == self.ws
            for con    in ws.descendants() if con.window  is not None]
        if len(windows) > 1:
            next = reduce(lambda a, v: v[1].id if windows[v[0]-1].focused
                    else a, enumerate(windows), 0)
            return ipc.command(fr'[con_id={next}] focus')


def flock(fname: os.PathLike):
    fd = open(fname, 'w')
    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    return fd


if __name__ == "__main__":
    try:
        i3conn = Connection()
        ws_switcher(conn=i3conn, lock=flock)
        print("Starting")
        i3conn.on(Event.SHUTDOWN, exit)
        i3conn.main()
        ws_switcher.unlock()
    except Exception as e:
        print(e.args)
        exit(1)
