"""Emit running processes for Alfred, one row each, as Activity Monitor lists them.

The query arrives as argv, and the kill action takes PIDs the same way, so no
query ever reaches a shell. That is the security design. The workflow this
replaces interpolated {query} into Ruby source, which it then interpolated into
a shell command, so a typed quote was a syntax error and a typed backtick ran
arbitrary code.

This script does its own matching rather than letting Alfred filter, because
Alfred stops honouring the rerun interval as soon as it filters results itself.

The list refreshes about once a second unless the query contains -p. Every
refresh rebuilds the list, and Alfred resets the selection to the first row
when it does, so arrow keys cannot reach anything further down while a refresh
is pending. -p pauses it for long enough to walk down the rows.

A paused list still asks for one refresh when it has no baseline to measure CPU
against. Rates come from differencing two samples, so a first run has nothing to
difference and falls back to the decaying average this design exists to avoid;
pausing outright would make that fallback permanent, and the topp and topmp
keywords open paused every time. The one rerun buys the second sample and then
stops, because by then there is a baseline.

-p rather than -s or -f. -s would read as sort next to -m, and -f reads as
force beside an action that kills. btop calls the same control pause.

Rows re-sort on every run rather than holding a pinned order. Pinning looks
like it would stop a refresh moving the row under the cursor. It does not,
because Alfred resets the selection to the first row on every rerun anyway, and
it costs accuracy. A process that turns busy after the list opens keeps
whatever rank it started with, and one at 100% CPU sat at row 714 of 716. -p
answers a moving cursor, because it stops the reruns.

The title is the executable's basename, which is what Activity Monitor puts in
its Process Name column. A Chrome renderer reads as `Brave Browser Helper
(Renderer)` rather than as its parent app, and a login shell's `-zsh` loses the
dash that marks it as one. Rows are per-PID, so a selection signals exactly one
process.

Two things that column cannot tell you are kept anyway:

  * The icon comes from the outermost .app in the path, so a helper shows the
    icon of the app it belongs to.
  * An interpreter is not a program. Stray processes all titled `Python` look
    identical, and only their argv says `fake_herdr.py`. The script name goes
    in the subtitle, and a query matches against it, so typing it finds those
    rows. A .framework path before the .app marks an interpreter's stub bundle,
    which is why Python.app is never mistaken for an app.

Matching is fzf's, used to filter and never to sort. A term matches as a
substring anywhere in the row, or as a subsequence of the process and script
names, so `bravhelp` reaches `Brave Browser Helper`. A subsequence is confined
to those two names because fzf pays for a loose match by ranking, and the order
here belongs to the load. Measured against the whole row, which carries the
path, `ssh` matches 289 of 806 rows rather than 1, and `brave` 501. Against the
names alone `ssh` is 33, and a leading ' makes a term exact, as it does in fzf.

Substring matches come before subsequence-only ones, which is the whole of the
ordering this matching imposes. Within each group the rows stay in load order,
so nothing that matched before a fuzzy term could reach it has moved relative to
anything else, and a loose match adds rows below rather than shuffling the list.
That is as far as it goes: `ssh` still returns 33 rows, and the exact operator
is what cuts them to 1.

Spawning fzf itself would buy its operators and cost the rest. `fzf -f` ranks
what it emits, which is the half of fzf this list cannot use, and every rerun
would wait on another binary resolved from the minimal PATH Alfred hands a GUI
process.

CPU is measured, not read. The %cpu that ps reports is a decaying average over
up to a minute, so a process that finished a burst 30 seconds ago still reads
busy. One sample here showed 58% where the true rate was 32%. Alfred reruns
this script about once a second while the list is open, which gives two samples
of cumulative cputime to difference, the same way top and Activity Monitor
compute it. The first run of a session has nothing to difference and falls back
to %cpu.

The list holds only this user's processes. `ps -A` would add the several
hundred root processes here that a kill from a GUI cannot signal, and a row
that silently fails is worse than an absent one.

The items carry no uid. Alfred treats uid as unique and collapses repeats, and
the obvious key, the process name, repeats across every helper. A PID is
unique, but macOS reuses it, so Alfred would be learning against a number that
means something else next week. The cost is that Alfred cannot reorder by
frecency, which the fixed order rules out anyway.

Two ps calls joined on PID, rather than one asking for both comm and args,
because each can contain spaces, and a single row of the two together cannot be
split back apart: `/Applications/Google Chrome.app/.../Google Chrome --type=x`
has no parseable boundary.
"""

import json
import os
import subprocess
import sys
import tempfile
import time

RERUN = 1.0
# The cache holds the baseline that the next rate is measured against, and a
# paused list is not rerunning to refresh it. Too short a window and -p falls
# back to the %cpu average this whole design exists to avoid; the cost of a
# longer one is only that the rate averages over a longer stretch.
STALE_AFTER = 60.0
MIN_SAMPLE = 0.3
# Single letters so they combine: -pm is a paused list sorted by memory. -l
# is accepted and means the default, so typing it out of habit does not turn
# into a search term that matches nothing.
FLAGS = "lmp"
PS = "/bin/ps"
CACHE_NAME = "sample.json"

INTERPRETERS = (
    "python",
    "node",
    "ruby",
    "perl",
    "bash",
    "sh",
    "zsh",
    "deno",
    "bun",
    "java",
    "osascript",
    "electron",
)


def ps(fmt):
    try:
        out = subprocess.run(
            [PS, "-u", str(os.getuid()), "-o", fmt],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return ""
    return out.decode("utf-8", "replace")


def number(text):
    try:
        return float(text)
    except (TypeError, ValueError):
        return 0.0


def cpu_seconds(text):
    """Parse ps cputime, which is [[hh:]mm:]ss.ff."""
    rest, _, seconds = text.rpartition(":")
    hours, _, minutes = rest.rpartition(":")
    return number(seconds) + 60 * number(minutes) + 3600 * number(hours)


def app_bundle(path):
    marker = path.find(".app/")
    if marker < 0:
        return None
    bundle = path[: marker + 4]
    # Python.app and the like are framework stubs rather than apps, and their
    # icon is the interpreter's, not that of anything the user launched.
    if ".framework/" in bundle:
        return None
    return bundle


def is_interpreter(name):
    stem = name.lower().split("-")[0]
    # python3.14, node22, ruby2.6.
    stem = stem.rstrip("0123456789.")
    return stem in INTERPRETERS


def script_name(argv):
    for arg in argv:
        # Everything after -c is code rather than a path. Its first word is
        # as often a shell builtin as anything, so a row named after it would
        # describe the wrong thing.
        if arg in ("-c", "-e"):
            return None
        if arg.startswith("-"):
            continue
        base = os.path.basename(arg)
        if base:
            return base
    return None


def icon_for(comm):
    bundle = app_bundle(comm)
    if bundle:
        return bundle
    # Alfred resolves a relative fileicon path against the workflow directory
    # and then draws nothing, with no error. A bare comm is real: a process
    # that exec'd without an absolute argv[0] reports one. Pointing at /bin/sh
    # makes macOS draw its own generic-executable icon, which beats naming an
    # .icns that Apple can move. The workflow this replaces named one, and it
    # is gone as of macOS 26.
    if os.path.isabs(comm) and os.path.exists(comm):
        return comm
    return "/bin/sh"


def human_bytes(kib):
    size = float(kib) * 1024
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024:
            precision = 0 if unit in ("B", "KB") or size >= 100 else 1
            return "{:.{}f} {}".format(size, precision, unit)
        size /= 1024
    return f"{size:.1f} TB"


def cache_path():
    root = os.environ.get("alfred_workflow_cache") or tempfile.gettempdir()
    try:
        os.makedirs(root, exist_ok=True)
    except OSError:
        root = tempfile.gettempdir()
    return os.path.join(root, CACHE_NAME)


def load_cache():
    try:
        with open(cache_path()) as fh:
            cached = json.load(fh)
    except (OSError, ValueError):
        return None
    if not isinstance(cached, dict):
        return None
    if time.time() - number(cached.get("at")) > STALE_AFTER:
        return None
    return cached


def save_cache(cached):
    path = cache_path()
    try:
        with open(path + ".tmp", "w") as fh:
            json.dump(cached, fh)
        os.replace(path + ".tmp", path)
    except OSError:
        pass


def collect():
    commands = {}
    for line in ps("pid=,%cpu=,rss=,cputime=,comm=").splitlines():
        parts = line.split(None, 4)
        if len(parts) == 5:
            commands[parts[0]] = parts

    arguments = {}
    for line in ps("pid=,args=").splitlines():
        parts = line.split(None, 1)
        if len(parts) == 2:
            arguments[parts[0]] = parts[1]

    mine = str(os.getpid())
    rows = []
    for pid, (_, average, rss, cputime, comm) in commands.items():
        # This script's own PID, and the ps that produced the row, have both
        # gone by the time Alfred draws the list. Offering either is the
        # silently-failing row the user filter exists to avoid.
        if pid == mine or comm == PS:
            continue
        # A login shell sets argv[0] to "-zsh", and ps reports that verbatim.
        # The dash is a marker, not part of the name, so Activity Monitor shows
        # these as plain "zsh" and a search for one has to find them.
        name = os.path.basename(comm.lstrip("-")) or comm
        args = arguments.get(pid, "")
        if args.startswith(comm):
            tail = args[len(comm) :]
        else:
            # A process exec'd as bare `node` reports an argv[0] that is not
            # the resolved comm path. Dropping the first token anyway keeps
            # script_name off the interpreter, which it would otherwise
            # return as the script and title every such row `Python`.
            _, _, tail = args.partition(" ")
        script = script_name(tail.split()) if is_interpreter(name) else None
        rows.append(
            {
                "pid": pid,
                "name": name,
                "script": script,
                "path": comm,
                "average": number(average),
                "cputime": cpu_seconds(cputime),
                "rss": number(rss),
            }
        )
    return rows


def measure(rows, sort):
    """Replace the decaying average with a true rate where two samples exist.

    Returns the rows and whether the cache could supply a rate at all, which is
    what a paused list waits for before it stops asking to be refreshed.
    """
    cached = load_cache() or {}
    previous = cached.get("cputime") or {}
    rates = cached.get("rate") or {}
    elapsed = time.time() - number(cached.get("at")) if cached else 0.0
    # Two samples a keystroke apart divide by a tiny elapsed and produce noise,
    # so a rate is only recomputed once the baseline is old enough to mean
    # something. Between those, the last rate carries forward, which is what
    # stops the numbers flickering while the user types.
    fresh = elapsed >= MIN_SAMPLE
    # Whether anything at all can be measured this run, rather than whether every
    # row was: a process that started since the last sample has no baseline of
    # its own and falls back to the average, and on a machine running several
    # hundred of them there is nearly always one. Waiting for all of them would
    # keep a paused list refreshing forever.
    baseline = bool(previous) or bool(rates)

    for row in rows:
        was = previous.get(row["pid"])
        if fresh and was is not None:
            row["cpu"] = max(0.0, (row["cputime"] - number(was)) / elapsed * 100)
        elif row["pid"] in rates:
            row["cpu"] = number(rates[row["pid"]])
        else:
            row["cpu"] = row["average"]

    if sort == "mem":
        rows.sort(key=lambda row: (row["rss"], row["cpu"]), reverse=True)
    else:
        rows.sort(key=lambda row: (row["cpu"], row["rss"]), reverse=True)

    keep = {"rate": {row["pid"]: row["cpu"] for row in rows}}
    if fresh or not cached:
        # Advancing the baseline on a keystroke would reset elapsed to nothing
        # every time and no sample would ever grow old enough to use.
        keep["at"] = time.time()
        keep["cputime"] = {row["pid"]: row["cputime"] for row in rows}
    else:
        keep["at"] = cached.get("at")
        keep["cputime"] = previous
    save_cache(keep)
    return rows, baseline


def subsequence(term, hay):
    """fzf's default match: every letter of the term, in order, gaps allowed."""
    at = 0
    for letter in term:
        at = hay.find(letter, at)
        if at < 0:
            return False
        at += 1
    return True


def matches(row, terms):
    """How well every term matches: 0 substring, 1 subsequence, None not at all.

    The rank is what keeps a fuzzy term additive. A row every term hits as a
    substring is one this list would have returned before subsequence matching
    existed, and it stays ahead of rows that only a subsequence reaches.
    """
    wide = " ".join(
        part for part in (row["name"], row["path"], row["pid"], row["script"]) if part
    ).lower()
    narrow = " ".join(part for part in (row["name"], row["script"]) if part).lower()

    rank = 0
    for term in terms:
        if term.startswith("'"):
            if term[1:] not in wide:
                return None
        elif term in wide:
            continue
        elif subsequence(term, narrow):
            rank = 1
        else:
            return None
    return rank


def items(query, sort):
    """The rows to show, and whether a paused list still owes itself a sample."""
    rows, baseline = measure(collect(), sort)
    terms = query.lower().split()
    if terms:
        # Two passes rather than a sort, so the load order inside each group is
        # the one measure() produced.
        ranked = [(matches(row, terms), row) for row in rows]
        rows = [row for rank, row in ranked if rank == 0]
        rows += [row for rank, row in ranked if rank == 1]

    out = []
    for row in rows:
        name = row["name"]
        pid = row["pid"]
        detail = [f"PID {pid}", human_bytes(row["rss"]), f"{row['cpu']:.1f}% CPU"]
        if row["script"]:
            detail.append(row["script"])
        detail.append(row["path"])
        out.append(
            {
                "title": name,
                "subtitle": "  ·  ".join(detail),
                "arg": pid,
                "icon": {"type": "fileicon", "path": icon_for(row["path"])},
                "variables": {"signal": "TERM", "name": name},
                "text": {"copy": pid, "largetype": f"{name}\n{row['path']}"},
                "mods": {
                    "cmd": {
                        "subtitle": f"Force quit PID {pid}  ·  SIGKILL, no saving",
                        "arg": pid,
                        "variables": {"signal": "KILL", "name": name},
                    },
                },
            }
        )
    return out, not baseline


def parse_args(argv):
    """Split the flag letters off the query. -lm means -l and -m together."""
    live = True
    sort = "cpu"
    terms = []
    for word in " ".join(argv).split():
        letters = word[1:]
        # A word is only a flag if every letter after the dash is one. That
        # leaves `-zsh`, which is what a login shell reports as its name, to
        # be searched for rather than swallowed.
        if word.startswith("-") and letters and set(letters) <= set(FLAGS):
            # Letter by letter, so the last one wins: -pl is live, -lp
            # paused. Testing only for "p" leaves -l unable to turn refreshing
            # back on.
            for letter in letters:
                if letter == "l":
                    live = True
                elif letter == "p":
                    live = False
                elif letter == "m":
                    sort = "mem"
            continue
        terms.append(word)
    return sort, " ".join(terms), live


def main():
    sort, query, live = parse_args(sys.argv[1:])
    found, pending = items(query, sort)
    if not found:
        found = [
            {
                "title": "No matching process",
                "subtitle": "Nothing this user can signal matches that",
                "valid": False,
            }
        ]
    response = {"items": found}
    if live:
        response["rerun"] = RERUN
    elif pending:
        # Paused with no baseline, so one more sample as soon as one is worth
        # taking. The run after it has a rate and asks for nothing.
        response["rerun"] = MIN_SAMPLE
    json.dump(response, sys.stdout)


if __name__ == "__main__":
    main()
