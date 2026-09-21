---
name: urbit-mcp
description: Operate an Urbit ship through the %mcp server. Use when the user asks you to read or change anything on their Urbit ship — run Dojo commands, read or write Clay files, build and test Hoon, manage desks and agents, or extend the MCP server itself with new tools, prompts, resources, or templates.
---

# Urbit MCP

The `%mcp` desk runs a Gall agent, `%mcp-server`, that exposes an Urbit ship
over the Model Context Protocol. Your MCP client connects to it over HTTP
(`<ship-url>/mcp` with an `urbauth` cookie). Tool names below appear in your
harness prefixed with the server name, e.g. `mcp__zod__mcp_scry-agent` for the
tool `mcp/scry-agent`.

## Ground rules

1. **Prefer the specific tool over `dojo/command`.** A scry, poke, file read,
   or desk commit each has its own tool with structured errors. Fall back to
   `dojo/command` only when no dedicated tool fits. Its input may span
   lines: a tall-form expression, or several commands that run in order
   and share state (`=foo 1`, then `(add foo 2)`). Each call gets a fresh
   Dojo session unless you pass `sole-id`; calls that share a `sole-id`
   share variables. Drop a named session with `dojo/close`.
2. **Verify Hoon on the ship.** After changing desk files that don't show up
   in the results of a `mcp/commit-desk` call, check with `mcp/test-build` or
   by committing the desk and reading the error output — nothing else proves
   the code compiles.
3. **Escape Hoon carefully.** Several tools take Hoon source as a string.
   Send it verbatim; do not "fix" `~`, `%`, or `@` sigils, and keep tall-form
   indentation exact (two spaces, no tabs).
4. **Paths in scries can interpolate.** `mcp/scry-agent` runs its `path`
   argument through `ream`, so `/(scot %p our)/...`-style interpolation works.
   Note that `=` stubs for paths only work in Dojo and `beam://` MCP Resources.

## Common workflows

### Read state from the ship

- Ship identity: `mcp/get-our-id`.
- Agent state: `mcp/scry-agent` with `agent` and a scry `path` that ends in
  `/json` (the endpoint must produce JSON for MCP compatibility).
- Files: `mcp/list-files` to enumerate, `mcp/get-file` to read.
- System facts (running agents, desk revisions, file hashes): read an MCP
  resource or fill a resource template — see
  [references/resources.md](references/resources.md).

### Change state on the ship

- Poke an agent: `mcp/poke-our-agent` with `agent`, `mark`, and `data` (a
  Hoon expression of the mark's type).
- Anything else: `dojo/command`; the tool enters each line of input in turn
  and returns the text Dojo printed.

### Develop Hoon on a desk

The edit–build–test loop, entirely through MCP:

1. `dojo/new-desk` and `dojo/mount-desk` if starting fresh.
   `mcp/commit-desk`.
2. `mcp/test-build` to compile one file and its dependencies and get
    build errors back. You should only need this for `/ted` and `/tests` files,
    everything else is built when you run `mcp/commit-desk`.
3. `mcp/run-tests` with a desk and path prefix to run unit/agent tests.
4. `mcp/install-app` to install a desk (local or remote)
5. `dojo/nuke-agent` and `dojo/revive-desk` to restart agents and fix
   `%load-failed` errors.

### Run Aqua tests

Aqua boots virtual ships inside the `%aqua` agent; `/ted/ph` threads drive
them. The `aqua/*` tools run such a thread in the background and capture what
the virtual ships print.

1. `aqua/pill` builds a brass pill and loads it into `%aqua`. `%aqua` must be
   running from `%base`; the tool says so if it is not. Rebuild the pill after
   changing a desk the virtual ships boot with.
2. `aqua/start` with `desk` and `path` (e.g. `/ted/ph/add`) returns a `runId`
   at once. One run is active at a time.
3. `aqua/read` with the `runId` returns one page of the run:
   - `status`: `starting`, `running`, `cancelling`, and `finishing` mean the
     run is still going. `finishing` drains pending effects. `completed`,
     `failed`, `cancelled`, and `interrupted` are final.
   - `records`: each has `cursor`, `ship`, `effect`, `type`, `text`,
     `observedAt`, `elapsedMs`, and `truncated`. The times are when the host
     saw the effect, not virtual-ship time.
   - `nextCursor`: pass it as `cursor` on the next read. It is exclusive, and
     it moves past records your `ships` and `effects` filters dropped. Reuse
     an old cursor to read the same records with other filters.
   - `hasMore`: more records are buffered now. It says nothing about whether
     the thread has finished; poll until `status` is final.
   - `gap`: present when the server evicted records before your cursor.
   - Only effect tags named at `aqua/start` are captured.
4. `aqua/cancel` stops the thread, not `%aqua` or its ships. `aqua/release`
   drops a finished run's records; the server keeps at most four runs.

### Extend the MCP server

Add or import tools, prompts, resources, and resource templates at runtime —
no recompile needed. See [references/extending.md](references/extending.md)
for the thread-builder signature, argument shapes, and the desk file layout
that `mcp/import-mcp-*` reads from.

Caution: `mcp/import-mcp-*` reads other agents' `/x/mcp/*` scries, not desk
files, so it cannot load a new file committed to the %mcp desk itself. To
register a new file on %mcp-server's own desk, run:

```
:mcp-server &add-tool -build-file /=mcp=/fil/mcp/tools/my-tool/hoon
```

through `dojo/command` (marks `%add-prompt`, `%add-resource`, `%add-template`
work the same way for the other feature kinds).

## Prompts and resources

The server also serves MCP **prompts** (slash commands in most harnesses,
e.g. `/mcp__zod__mcp_dojo`) and **resources** (@-mentions, e.g.
`@zod:https://docs.urbit.org/llms.txt`).

Resources cover Urbit docs, system source (`zuse`, `spider`, `strandio`), and
live listings of the server's own tools, prompts, resources, and templates.
Templates parameterize scries over Clay, Gall, and remote ships. Details in
[references/resources.md](references/resources.md).
