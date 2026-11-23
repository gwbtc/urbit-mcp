# Resources and resource templates

Resources are readable by URI through MCP `resources/read`; many harnesses
expose them as @-mentions (e.g. `@zod:https://docs.urbit.org/llms.txt`).
Templates are resources with `{placeholder}` segments you fill in before
reading. `{+name}` matches a multi-segment path tail; `{case}` is a Clay
revision (number, date, or `~` label — for the current revision, ask for the
desk revision first via `arvo/clay/revision`).

## Supported URI schemes

- `https://` — the server fetches a public web page.
- `beam://` — a file in Clay, as `beam://<ship>/<desk>/<case>/<path>`; `=`
  means "current" for ship and case, e.g. `beam://=/base/=/sys/zuse/hoon`.
  This `=` syntax is only supported for `beam://` and in the Dojo.
- `scry://` — an Arvo or Gall scry; the first segment is the vane care
  (`cx`, `gx`, etc.).
- `fine://` — remote scry against another ship. Will attempt a public `%keen`
   scry and automatically fall back to a two-way encrypted `%chum` scry if
   that fails.

## Useful default resources

| Name | URI | Contents |
|---|---|---|
| `mcp/docs/llms` | `https://docs.urbit.org/llms.txt` | Urbit docs index for LLMs |
| `mcp/docs/strandio` | `https://docs.urbit.org/urbit-os/base/threads/strandio.md` | Strandio thread API docs |
| `mcp/spider` | `beam://=/base/=/sur/spider/hoon` | Spider structures |
| `mcp/strandio` | `beam://=/base/=/lib/strandio/hoon` | Strandio library source |
| `mcp/mcp-servers` | `scry://gx/mcp-proxy/servers/json` | Remote MCP servers and their cached tools |
| `mcp/blocked-tools` | `scry://gx/mcp-proxy/blocked/json` | Tools hidden from `tools/list`, by server id |

Read `mcp/strandio` and `mcp/spider` before writing a thread-builder — they
define the API your tool code runs against.

## Prompts

Prompts show up as slash commands in most harnesses
(`/mcp__<server>__<name>`). Defaults mirror the common tools (`mcp/dojo`,
`mcp/get-file`, `mcp/commit-desk`, `mcp/run-tests`, `mcp/test-build`,
`mcp/install-app`, `mcp/mount-desk`, `mcp/nuke-agent`, `mcp/revive-desk`,
`mcp/get-our-id`).
