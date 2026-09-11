---
name: noslop
description: Strip AI slop from a change, code first and then prose.
disable-model-invocation: true
---

# noslop

Run both halves of the slop removal in order. `deslop` cleans the code, then the
`unslop` rules clean the prose.

## Scope

Use the argument if one is given. With no argument, take the uncommitted
changes: `git diff`, `git diff --staged`, and untracked files.

Fix the scope once, before either pass, so both passes read the same files.

## Pass 1, code

Invoke `pstack-skills:deslop` and follow it, guardrails included.

Some of its focus areas assume Cursor's TypeScript stack. Casts to `any` and
try/catch blocks have no equivalent in a shell, Lua or TOML repo, so read those
as inert. It also says to diff against `main`, so use this repo's default
branch.

Done when every file in scope is read and every finding is either fixed or
deliberately left.

## Pass 2, prose

`unslop` sets `disable-model-invocation: true`, so the Skill tool cannot reach
it. Read the rules from the file instead:

```
~/.claude/skills/pstack-skills/skills/unslop/SKILL.md
```

Apply them to every piece of prose the change touches:

- comments that survived pass 1
- Markdown and other docs in the diff
- the commit message, if you are about to write one
- your own closing summary to the user

Pass 1 decides which comments live, so it runs first. Pass 2 then fixes how the
survivors read.

Done when every target above has been checked against every rule in that file.

## The repo wins

A standard the repo documents overrides both skills. Where `CLAUDE.md`,
`CONTRIBUTING.md` or a coding standards file endorses something these rules
would flag, leave it.

## Guardrails

- Re-run the repo's tests afterwards and report the result.
- Stop at the diff and show it. Committing is the user's call.
