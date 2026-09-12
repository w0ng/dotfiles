#!/usr/bin/env python3
"""Hold the agent counts the bar draws, and trigger one sketchybar event when
they change.

A subscription to pane.agent_status_changed delivers within the same second an
agent's status moves. The counts still come from a fresh agent.list rather than
from the event body, because agent.list is the only authority on which agents
exist and reading it costs ~0.18ms on the socket with no process spawn.

Nothing here recognises an event by name. herdr has renamed these between
protocol versions, so a watcher that matched on names would stop updating and
report nothing wrong. Any frame at all means "read again".

pane.agent_status_changed is per pane, so the subscription is rebuilt whenever
the set of agent panes changes. The global lifecycle events say when that has
happened, and the reading after every frame notices it either way.

POLL only covers a frame that never arrives. The subscription does the work.

Started by sketchybarrc, which also stops the previous copy. This is python
rather than shell because the herdr API is JSON over a unix socket, which bash
can neither hold open nor parse.
"""

import json
import os
import shutil
import socket
import subprocess
import time

STATE = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
    "sketchybar",
    "ai_agents",
)
SOCK = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser(
    "~/.config/herdr/herdr.sock"
)

# Longest the bar can sit on a stale reading if a frame is ever missed.
POLL = 5.0
# Wait before reconnecting, so a herdr restart, a dropped stream or a refused
# subscription is not met with a reconnect storm.
RETRY = 3.0
# Consecutive unreadable polls before the counts are blanked. A restart takes a
# moment and should not clear the bar, but once the counts have been unreadable
# this long, showing none is better than showing the last reading.
BLANK_AFTER = 5
ZERO = (0, 0, 0, 0, 0)

LIFECYCLE = [
    {"type": "pane.agent_detected"},
    {"type": "pane.created"},
    {"type": "pane.closed"},
    {"type": "pane.exited"},
]


def connect(timeout):
    connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    connection.settimeout(timeout)
    connection.connect(SOCK)
    return connection


def request(method, params=None):
    """One request on its own connection; the server closes after replying."""
    connection = connect(5)
    try:
        payload = {"id": method, "method": method, "params": params or {}}
        connection.sendall((json.dumps(payload) + "\n").encode())
        buffered = b""
        while b"\n" not in buffered:
            chunk = connection.recv(65536)
            if not chunk:
                break
            buffered += chunk
        lines = buffered.decode("utf-8", "replace").splitlines()
        if not lines:
            raise ValueError("empty reply from the herdr socket")
        return json.loads(lines[0])
    finally:
        connection.close()


def read():
    """One tally per agent_status, plus the panes those agents are in.

    Nothing is derived. herdr already tracks "done", meaning a turn that
    finished and has not been looked at yet, and clears it itself once the pane
    is visited. There is no transition or focus bookkeeping to do here.
    """
    agents = request("agent.list")["result"]["agents"]
    tally = {"working": 0, "blocked": 0, "done": 0, "idle": 0}
    panes = set()
    for agent in agents:
        status = agent.get("agent_status")
        # "unknown" is a transcript viewer or model picker sitting over the
        # session, and is also what a pane reports for a second or two before
        # herdr recognises the agent. A view rather than a state, so it reads as
        # idle instead of earning a colour and flickering on the bar.
        tally[status if status in tally else "idle"] += 1
        if agent.get("pane_id"):
            panes.add(agent["pane_id"])
    counts = (
        len(agents),
        tally["working"],
        tally["blocked"],
        tally["done"],
        tally["idle"],
    )
    return counts, frozenset(panes)


def publish(current, holder):
    """Write the counts, and trigger the bar only when they have moved.

    `holder` carries the last published reading rather than a return value, so
    that an exception raised later in the loop cannot lose it and cause a
    spurious repaint on the next pass.
    """
    total, working, blocked, done, idle = current
    changed = current != holder.get("counts")
    if changed or not os.path.exists(STATE):
        # The directory is made here rather than once at startup, because
        # clearing ~/.cache takes it with it and every later write would fail.
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        # Written whole and moved into place, so a repaint can never read half a
        # file and blank the segment.
        tmp = STATE + ".tmp"
        with open(tmp, "w") as handle:
            handle.write(
                f"total={total}\nworking={working}\nblocked={blocked}\n"
                f"done={done}\nidle={idle}\n"
            )
        os.replace(tmp, STATE)
    if changed:
        # Timed out, because a wedged sketchybar would otherwise block the
        # watcher for good and the safety net could never fire.
        subprocess.run(
            ["sketchybar", "--trigger", "ai_change"], capture_output=True, timeout=5
        )
    holder["counts"] = current


def watch(panes, holder):
    """Subscribe for these panes and read on every frame.

    Returns when the set of agent panes changes, so the caller can subscribe
    again for the new set. Raises on a refused subscription or a closed stream,
    so that the caller backs off rather than reconnecting at once.
    """
    connection = connect(5)
    try:
        subscriptions = [
            {"type": "pane.agent_status_changed", "pane_id": pane} for pane in panes
        ] + LIFECYCLE
        connection.sendall(
            (
                json.dumps(
                    {
                        "id": "sketchybar",
                        "method": "events.subscribe",
                        "params": {"subscriptions": subscriptions},
                    }
                )
                + "\n"
            ).encode()
        )

        # herdr answers an unusable subscription with an error and keeps the
        # connection open, which would otherwise look exactly like a herd that
        # never changes.
        acknowledgement = connection.recv(65536).decode("utf-8", "replace")
        first = acknowledgement.splitlines()[0] if acknowledgement else ""
        if '"subscription_started"' not in first:
            raise ValueError(f"herdr refused the subscription: {first[:200]}")

        # Anything that moved between the reading above and the subscription
        # taking effect is caught here rather than waiting for POLL.
        counts, current = read()
        publish(counts, holder)
        if current != panes:
            return

        connection.settimeout(POLL)
        while True:
            try:
                if not connection.recv(65536):
                    raise ConnectionError("herdr closed the subscription stream")
            except socket.timeout:
                pass
            counts, current = read()
            publish(counts, holder)
            if current != panes:
                return
    finally:
        connection.close()


def main():
    # Its own session, so that whatever launched it taking down its process
    # group on exit does not take this with it. sketchybar runs the config as a
    # child and does exactly that.
    try:
        os.setsid()
    except OSError:
        pass

    holder = {"counts": None}
    failures = 0
    while True:
        try:
            counts, panes = read()
            # Reset before subscribing, so that a dropped stream never counts
            # towards blanking a herd that reads perfectly well.
            failures = 0
            publish(counts, holder)
            watch(panes, holder)
            # Skips the backoff below, which is only for failures.
            continue
        except Exception:
            failures += 1
            if failures == BLANK_AFTER:
                try:
                    publish(ZERO, holder)
                except Exception:
                    pass
        time.sleep(RETRY)


if shutil.which("herdr"):
    main()
else:
    # Leaving the last file behind would keep the bar painting counts for a herd
    # that can no longer exist.
    try:
        os.remove(STATE)
    except OSError:
        pass
