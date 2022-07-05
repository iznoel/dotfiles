#!/usr/bin/env python3

from i3ipc import Connection, Event, events
from functools import reduce
from collections.abc import Callable
import fcntl

DEBUG = False

"""

"""


def flock(fname: str):
    try:
        fd = open(fname, 'w')
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as e:
        print("i3-wss is already running.")
        exit(e.args[0])
    else:
        return fd


class ws_switcher:
    def __init__(self, ipc: Connection, lock: Callable[[str], object] = flock):
        self.locked = lock(f"{ipc.socket_path}.ws-switcher.lock")
        self.ipc = ipc

        self.set_current_ws(self.check_current_workspace())
        self.cycling = self.ws
        self.cached = {}

        self.ipc.on(Event.BINDING,         self.on_route_bind)
        self.ipc.on(Event.WORKSPACE_FOCUS, self.on_workspace_focus)

    def command(self, cmd):
        if DEBUG: print('DEBUG', cmd)
        self.ipc.command(cmd)

    def on_workspace_focus(self, ipc: Connection, event: events.WorkspaceEvent):
        if DEBUG: print('on_workspace_focus')
        self.set_current_ws(event.ipc_data['current'])

    def on_route_bind(self, ipc: Connection, event: events.BindingEvent):
        if DEBUG: print('on_route_bind')
        bind = event.binding.command
        if not bind.startswith('nop'):
            return
        elif self.cached.get(bind):
            self.cached[bind]()
        else:
            instruction = tuple(filter(len, bind.split(' ')))[1:]
            if instruction[0] == 'wss':
                self.cached[bind] = self.route(instruction[1:])
                self.cached[bind]()

    def route(self,
            bind:  tuple,
            stack: Callable|None = None):
        if DEBUG: print(f'route {bind}')
        match bind:

            case ('or'|'and', *rest):
                if DEBUG: print('or')
                call_rest = self.route(rest, stack)
                if bind[0] == 'or':
                    return lambda: stack is None or stack() or call_rest()
                else:
                    return lambda: stack is None or stack() and call_rest()

            case ('workspace'|'ws', 'number'|'num', nr, *rest):
                if DEBUG: print('ws num nr')
                return self.route(rest, lambda: self.to_workspace(int(nr)))

            case ('workspace'|'ws', 'next'|'prev', *rest):
                if DEBUG: print('next|prev workspace')
                dir = bind[1]
                if 'any' in rest:
                    del rest[rest.index('any')]
                    return self.route(rest, lambda: self.cycle_workspace_all(dir))
                else:
                    return self.route(rest, lambda: self.cycle_workspace_same(dir))

            case ('window'|'win', 'next'|'prev', *rest):
                if DEBUG: print('next|prev window')
                dir = bind[1]
                return self.route(rest, lambda: self.cycle_window(dir))

        return stack

    def cycle_workspace_same(self, direction: str):
        # https://www.reddit.com/r/i3wm/comments/vpo4ph/move_to_workspace_x10
        if DEBUG: print('-- cycle_workspace_same')
        if not self.cycling == self.ws:
            self.cycling = self.ws
            return self.to_workspace(self.ws)
        workspaces = [ws
            for ws in self.ipc.get_workspaces()
            if ws.num == self.ws]
        get_next = self.next_con if direction == 'next' else self.prev_con
        self.command(f'workspace "{get_next(workspaces).name}"')
        return True

    def cycle_workspace_all(self, direction: str):
        # if DEBUG: print('-- cycle_workspace_all')
        """
            cycle through all workspaces,
                unlike i3 'workspace [next|prev]' this method does not skip
                workspaces with the same 'number'
        """
        workspaces = self.ipc.get_workspaces()
        if direction == 'prev':
            ws = self.prev_con(workspaces)
        else:
            ws = self.next_con(workspaces)
        self.command(f'workspace "{ws.name}"')
        return True

    def cycle_window(self, direction: str):
        if DEBUG: print('-- cycle_window')
        windows = [con
            for output in self.ipc.get_tree() if output.name != '__i3'
            for ws     in output.nodes        if ws.id      == self.wsid
            for con    in ws.descendants()    if con.window]
        if len(windows) > 1:
            if direction == 'prev':
                con = self.prev_con(windows).id
            else:
                con = self.next_con(windows).id
            self.command(f'[con_id={con}] focus')
            return True

    def anything(self,  ws: int, cmd: str):
        if DEBUG: print('-- anything')
        if not self.to_workspace(ws):
            self.command(cmd)

    def to_workspace(self, ws: int):
        if DEBUG: print('-- to_workspace')
        if self.ws != ws:
            self.command(f'workspace number {ws}')
            return True

    @classmethod
    def next_con(cls, con: list):
        if DEBUG: print('-- next_con')
        return reduce(lambda a, v: v[1] if con[v[0]-1].focused else a,
            enumerate(con), 0)

    @classmethod
    def prev_con(cls, con: list):
        if DEBUG: print('-- prev_con')
        max = len(con)
        return reduce(lambda a, v: v[1] if con[(v[0]+1) % max].focused else a,
            enumerate(con), 0)

    def set_current_ws(self, ws: dict):
        if DEBUG: print('-- set_current_ws')
        self.ws   = ws['num']
        self.wsid = ws['id']

    def check_current_workspace(self):
        if DEBUG: print('-- check_current_workspace')
        return reduce(
            lambda a, v: v.ipc_data if v.focused else a,
            self.ipc.get_workspaces(), 0)


def getpair(args: list, keys: list[str, Callable|None]) -> tuple[list, dict]:
    results = {}
    for [key, check] in keys:
        try:
            idx = args.index(key)
            val = args[idx+1]
            if not check or check(val):
                results[key] = val
        except ValueError: continue
        else: del args[idx], args[idx-1]
    return [args, results]


if __name__ == "__main__":
    i3conn = Connection()
    ws_switcher(i3conn)
    i3conn.on(Event.SHUTDOWN, lambda _: exit(0) )
    i3conn.main()
