---
name: herdr-dispatch
description: Use when the user asks for work to happen in a new herdr target — "create a new workspace", "open a new tab", "spawn a claude in a pane", "split and ...", "start this in another window", "spawn a worktree and open claude in it". Dispatches a fresh claude into the new target instead of doing the task inline.
version: 2.0.0
---

# Herdr Dispatch

Dispatch a cold `claude` into a new herdr target, report briefly, and **stop — do not also do
the task here.**

## Skip when

- `HERDR_TASK` is set — you _are_ the worker. Just do the task.
- No new target was asked for. Do it here.
- `herdr-task` says `not inside a herdr session` — do the work here, say the dispatch didn't
  happen, don't retry.

## Dispatch

Task detail always goes in a brief file; the command line carries only a pointer to it.

```bash
briefs="${XDG_STATE_HOME:-$HOME/.local/state}/claude-briefs"
mkdir -p "$briefs"
find "$briefs" -maxdepth 1 -name '*.md' -mtime +30 -delete
slug="$(printf '%s' "<label>" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-*$//')"
brief="$briefs/$slug-$(date +%Y%m%d-%H%M%S).md"
# Write the brief with the Write tool, then:
pointer="Read $brief — it is your full brief. Print it back in full before doing anything else, then follow it."
herdr-task "<label>" <--workspace|--tab|--split right> <--focus|--no-focus> --cwd <path> \
  -- claude "$pointer"
```

Don't delete the brief after dispatch — the worker re-reads it once its own context compacts.

**Brief content** — the worker starts cold: ticket id/URL, links, constraints, what "done" means.

**Target**

| They say         | Flag                                                  |
| ---------------- | ----------------------------------------------------- |
| "workspace"      | `--workspace` (default; isolated context)             |
| "tab"            | `--tab` (new tab in the current workspace)            |
| "pane" / "split" | `--split right` (`--split down` for below/horizontal) |

**Focus** — `--focus`, unless they say otherwise ("in the background", "keep working here",
"don't switch me"). `--no-focus` is the script's default.

**`--cwd`** — defaults to the git repo root, not `$PWD`. Pass it for a subdirectory or elsewhere.

## Worktree dispatch

Two hops — never create the worktree in this session.

1. Ticket → branch name (look up Jira for a short description; naming lives in CLAUDE.md).
2. Write two briefs: `<slug>.md` is the real task, `<slug>-build.md` is the builder's. The build
   brief says to run `path=$(wt new <branch>)` — `wt co` for someone else's branch, using the
   path it prints, never a guessed worktree path — then exactly this and nothing else,
   explicitly **not** doing `<slug>.md` itself:

   ```bash
   herdr-task "<label>" --tab --no-focus --cwd "$path" -- claude "$pointer"   # pointer to <slug>.md
   herdr notification show "<label> ready" --body "worktree built, claude is up" --sound done
   herdr pane close "$HERDR_PANE_ID"
   ```

   Close last: it kills the builder's own claude. If `wt` failed, run none of the three and leave
   the builder open as the error.

3. Dispatch the builder:

   ```bash
   herdr-task "<label> build" --workspace --no-focus --cwd <main checkout> \
     -- claude "$pointer"   # pointer to <slug>-build.md
   ```

## Report

Then stop.

- **Simple dispatch** — the target and the brief path:

  > Dispatched to tab `plan-holidays` — focused.
  > Brief: `~/.local/state/claude-briefs/plan-holidays-20260814-193404.md`

- **Worktree dispatch** — the builder workspace, that a notification fires when the worktree is
  built, and that a failed `wt` leaves the builder open as a blocked agent rather than erroring
  here.
