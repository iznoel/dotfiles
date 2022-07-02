#!/usr/bin/env python3

from i3ipc import Connection, Event, Con, events
from functools import reduce
from collections.abc import Callable
import fcntl
import json

"""
# Next window on workspace
bindsym $mod+1 nop workspace number 1 or next window

# Open workspace or (repeat) previous workspace
bindsym $mod+1 nop ws num 1 or prev

# Run arbitrary command if you're already on the desired workspace
bindsym $mod+1 nop ws num 1 or workspace back_and_forth
bindsym $mod+1 nop ws num 1 or scratchpad hide

Example config
--------------
exec_always --no-startup-id i3-nop-ws.py
"""

class ws_switcher:
    def __init__(self, ipc: Connection,
            lock: Callable[[str], object]):
        self.locked = lock(f"{ipc.socket_path}.ws-switcher.lock")
        self.check_current_workspace(ipc)
        self.cycling = self.ws
        ipc.on(Event.BINDING, self.route_bind)
        ipc.on(Event.WORKSPACE_FOCUS, self.on_workspace_focus)

    def route_bind(self, ipc: Connection, event: events.BindingEvent):
        bind = event.binding.command
        if not bind.startswith('nop'):
            return
        instruction = tuple(filter(len, bind.split(' ')))[1:]
        match instruction:
            case ('workspace' | 'ws', 'number' | 'num',
                    nr, 'or', *rest) if nr.isnumeric():
                nr = int(nr)
                match rest:
                    case ('next' | 'prev' , 'window'):
                        self.on_cycle_window(ipc, nr, rest[0])
                    case ('next' | 'prev',):
                        self.on_cycle_workspace(ipc, nr, rest[0])
                    case _:
                        self.on_anything(ipc, nr, ' '.join(rest))

    def on_cycle_workspace(self, ipc: Connection, ws: int, direction: str):
        if self.cycling == ws:
            ipc.command(f'workspace {direction}')
        else:
            self.to_workspace(ipc, ws)
            self.cycling = ws

    def on_cycle_window(self, ipc: Connection, ws: int, direction: str):
        if not self.to_workspace(ipc, ws):
            windows = [con
                for output in ipc.get_tree()   if output.name != '__i3'
                for ws     in output.nodes     if ws.id      == self.wsid
                for con    in ws.descendants() if con.window]
            if len(windows) > 1:
                if direction == 'prev':
                    con = self.prev_window(windows)
                else:
                    con = self.next_window(windows)
                ipc.command(f'[con_id={con}] focus')

    def on_anything(self,  ipc: Connection, ws: int, cmd: str):
        if not self.to_workspace(ipc, ws):
            ipc.command(cmd)

    def to_workspace(self, ipc: Connection, ws: int):
        if self.ws != ws:
            ipc.command(f'workspace number {ws}')
            return True

    @classmethod
    def next_window(cls, windows: list):
        return reduce(lambda a, v:
            v[1].id if windows[v[0]-1].focused else a,
            enumerate(windows), 0)

    @classmethod
    def prev_window(cls, windows: list):
        max = len(windows)
        return reduce(lambda a, v:
            v[1].id if windows[v[0]+1 % max].focused else a,
            enumerate(windows), 0)

    def set_current_ws(self, ws: dict):
        self.ws   = ws['num']
        self.wsid = ws['id']

    def on_workspace_focus(self, ipc: Connection, event: events.WorkspaceEvent):
        self.set_current_ws(event.ipc_data['current'])

    def check_current_workspace(self, ipc: Connection):
        self.set_current_ws(reduce(
            lambda a, v: v.ipc_data if v.focused else a,
            ipc.get_workspaces(), 0))

def flock(fname: str):
    fd = open(fname, 'w')
    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    return fd


if __name__ == "__main__":
    i3conn = Connection()
    ws_switcher(i3conn, lock=flock)
    i3conn.on(Event.SHUTDOWN, lambda _: exit(0) )
    i3conn.main()
