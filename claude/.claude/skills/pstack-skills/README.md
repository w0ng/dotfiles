# pstack-skills

Two vendored skills that strip AI slop, one for prose and one for code.

| Skill | Cuts | Invocation |
| --- | --- | --- |
| `pstack-skills:unslop` | AI tells in prose: 28 rules, numbered 3 to 33 | You only |
| `pstack-skills:deslop` | Slop in code: comments, guards, casts, nesting | You or Claude |

`unslop` sets `disable-model-invocation: true`, so Claude cannot reach it. Type
its name, or read `skills/unslop/SKILL.md` directly when you want the rules
without the skill system. `deslop` carries a description, so Claude fires it on
its own.

They do not overlap. `unslop` never touches code structure, and `deslop` reads a
code diff. pstack's own guide puts it as "`/deslop` cleans slop out of the code,
`/unslop` cleans it out of prose".

`deslop` was written for Cursor's stack. It says to diff against `main`, which
is `master` here, and one of its five focus areas is TypeScript-only. Another,
try/catch, has no equivalent in this repo's shell and Lua. Read those as inert
rather than editing the file, which would break the refresh diff below.

## Where these came from

Both files are copied byte for byte from Cursor's plugin marketplace, which is
MIT licensed:

- `skills/unslop/SKILL.md` from
  [`cursor/plugins/pstack`](https://github.com/cursor/plugins/blob/main/pstack/skills/unslop/SKILL.md),
  by Lauren Tan.
- `skills/deslop/SKILL.md` from
  [`cursor/plugins/cursor-team-kit`](https://github.com/cursor/plugins/blob/main/cursor-team-kit/skills/deslop/SKILL.md),
  by Cursor.

pstack ships `unslop` but deliberately leaves `deslop` in `cursor-team-kit` and
tells you to install both. This package is that pairing, without the other 46
pstack skills.

## Why these are copies, not an installed plugin

`cursor/plugins` ships `.cursor-plugin/marketplace.json`. Claude Code reads
`.claude-plugin/marketplace.json` and nothing else, so
`claude plugin marketplace add cursor/plugins` fails on the manifest even though
`claude plugin validate` passes on the skill content itself. Copying the two
files is how to run them under Claude Code.

## Refreshing a copy

Compare against upstream, and overwrite only if you want the change:

```sh
diff <(curl -sL https://raw.githubusercontent.com/cursor/plugins/main/pstack/skills/unslop/SKILL.md) \
  skills/unslop/SKILL.md
```

Keep the copies verbatim. Local edits make that diff unreadable, and the next
refresh silently drops them.
