# Urbit MCP

A general-purpose Model Context Protocol interface for Urbit.

## Quickstart

The fastest way to get a running Urbit with MCP configured is to [install Groundwire](https://groundwire.io/). The onboarding script will automatically configure your ship for Codex, Claude Code, and Opencode.

```bash
curl -fsSL https://groundwire.io/install.sh | bash
```

If you don't need your LLM to have a self-custodied decentralized ID, you can skip the attestation flow.

```bash
curl -fsSL https://groundwire.io/install.sh | bash -s -- --skip-attestation
```

Note that this will configure a hard-coded cookie which will eventually expire. Your ship's local Codex and Opencode config files link to this README, which has instructions for getting a new cookie.

## Build from source

### 1. Build and Install

- *Requires a running [Urbit](https://docs.urbit.org/get-on-urbit) ship, real or fake, running on a machine you have terminal access to.*
- *Requires [Zig](https://ziglang.org/download/) 0.15 or newer. Make sure `zig version` works.*

Create and mount the desk on your Urbit ship:

```dojo
> |new-desk %mcp
> |mount %mcp
```

In the `urbit-mcp` folder, run `zig build`. By default this will install dependencies into `/zig-out` in this folder. Use `--prefix`/`-p` to choose another output directory, and use the `-Ddesk` option to additionally replace the contents of your ship's desk with your source desk.

```bash
$ cd urbit-mcp
$ zig build -Ddesk=~/path/to/zod/mcp
```

```dojo
> |commit %mcp
> |install our %mcp
```

### 2. Authentication Setup

Get your ship's web login code from the Dojo:

```dojo
> +code
lidlut-tabwed-pillex-ridrup
~zod:dojo>
```

Authenticate and get session cookie:

```bash
curl -i http://localhost:80/~/login -X POST -d "password=lidlut-tabwed-pillex-ridrup"
```

Extract the cookie from the `set-cookie` header, which will look like this:

```
urbauth-~your-ship=0v3.j2062.1prp1.qne4e.goq3h.ksudm
```

### 3a. Register with Codex

Simply add this to your `~/.codex/config.toml`:

```toml
[mcp_servers.zod]
enabled = true
url = "http://localhost:80/mcp"
http_headers = { "Cookie" = "urbauth-~your-ship=0v3.j2062.1prp1.qne4e.goq3h.ksudm" }
```

### 3b. Register with Claude Code

Add the MCP server to Claude using HTTP transport:

```bash
claude mcp add --transport http zod http://localhost:80/mcp --header "Cookie: urbauth-~your-ship=0v3.j2062.1prp1.qne4e.goq3h.ksudm" --scope user
```

## Usage

### Tools

Just ask! You can see the default tools [here](./desk/fil/default/mcp/tools).

You can ask your LLM to add new Tools. Give it a description (and ideally, examples) and it will do its best, or provide a Hoon thread for it to adapt to run in `%mcp-server`. Threads in `%mcp-server` must be of signature `$-((map @t argument:tool:mcp) shed:khan)`.

### Managed Aqua runs

`aqua/start` starts a Spider thread without waiting for it to finish. Pass `desk`, `path` (for example `/ted/ph/add`), and optionally `arg` as raw Hoon. The ship must have `%aqua` running with a pill loaded.

`aqua/pill` loads that pill. It builds a brass pill with `prime` and `cache` on, pokes it into `%aqua`, and returns Dojo's output once `%aqua` has the pill. Pass `desks` to include desks besides the base desk, and `base` to name a base desk other than `%base`. The tool first checks that `%aqua` is running from the `%base` desk; if not, it returns an error that says how to start it. Building and priming a pill takes minutes.

Use the returned `runId` with `aqua/read`. Each page contains JSON records with `cursor`, `ship`, `effect`, `type`, `text`, `observedAt`, `elapsedMs`, and `truncated`, plus run status and `nextCursor`. Pass that cursor on subsequent reads. Optional `ships` and `effects` arrays filter records; `includePrompts` includes Dojo prompts. Filters advance the cursor over nonmatching records. Timestamps measure when the host observed an effect, not virtual-ship time.

Default capture tags are `blit`, `init`, `sleep`, `restore`, and `kill`. `blit` output is rendered as plain text, including nested and colored frames. Other supported tags are opt-in metadata summaries; raw nouns, network packets, HTTP bodies, filesystem exports, returned vases, and error tangs are not retained. Effects are decoded envelope-first: unknown tags (including Groundwire's `fief` and `avow`) and filtered tags are skipped without inspecting their payloads. Selected effects decode only fields needed for rendering; malformed records increment the run's omitted counter instead of failing the subscription. Network summaries show the immediate lane target and `decodedBy` method. One decoder handles upstream's special comet and Groundwire's 12 synthetic comet addresses, without build options or a fief cache. Push summaries inspect at most four lanes and mark additional lanes as truncated. These are Aqua lane conventions, not general IP resolution or sender-specific fief remapping; unrecognized lanes are shown as unresolved. Packet recipients are not decoded. Runtime slog hints (`~&` and `~?`) are not part of `/effect` and are not captured.

Storage is bounded to four runs, 2,048 records and 1 MiB of encoded record data per run, with bounded per-ship partial lines. Records are capped at 4 KiB and 512 Unicode characters. Old records are evicted; a `gap` reports skipped cursor ranges. Starting a fifth run evicts the oldest retained run. One managed run can be active at a time because Aqua is a shared simulation instance; unrelated Aqua activity is not isolated from the captured stream.

`maxBytes` controls the serialized JSON page budget (8–32 KiB). The existing server also duplicates structured data into MCP's text content, so the full response is larger (including JSON escaping). Clients can save JSON pages for programmatic analysis instead of displaying every record to a model.

`aqua/cancel` stops the managed Spider thread and its children, not `%aqua` or its virtual ships. `aqua/release` deletes a finished run's retained data. An agent reload interrupts and stops an active managed thread.

After Spider reports completion, a run briefly remains `finishing` until the next host kernel turn. A Behn wake scheduled one logical tick ahead provides this event boundary: the current event's pending effects drain before finalization flushes partial lines and unsubscribes. This is not a wall-clock grace period and does not inject virtual-ship events.

### Prompts (slash commands)

Depending on your agent harness, MCP prompts for most default tools may be available as slash commands, e.g. `/mcp__zod__<tool name>`.

Running these will append a prompt snippet to the conversation and call out to the LLM provider. You can ask your LLM to add new Prompts.

### Resources (@ mentions)

Depending on your agent harness, MCP resources may be referenced with an `@` mention to pull their contents into the context window.

```
@zod:https://docs.urbit.org/llms.txt
```

You can ask your LLM to add new Resources by providing an `https://` URI to a public webpage or a `beam://` URI to a file in your Urbit's Clay filesystem.

## Contributing

This repo requires commits to be signed with a [Groundwire](https://groundwire.io/) identity. PRs with unsigned commits will be rejected by CI.

### Setup commit signing

You need an Urbit ship running the `%vitriol` agent.

**Quick install:**

```bash
./hooks/install.sh <your-ship-url>/vitriol "<auth-cookie>"
```

**Manual install:**

```bash
git config gpg.program /path/to/hooks/groundwire-sign
git config commit.gpgsign true
git config groundwire.sign-endpoint <your-ship-url>/vitriol
git config groundwire.sign-token "<auth-cookie>"
```

Once configured, all commits will be automatically signed with your ship's Ed25519 networking key. The CI verifies signatures against on-chain keys via [vitriol.bot](https://vitriol.bot).

### Re-signing existing commits

If you have unsigned commits on a branch:

```bash
git rebase --exec "true" HEAD~N
```

(where N is the number of commits to re-sign)

## Development

### Build Commands

- `zig build` - Build `/desk` and dependencies into `/zig-out`
- `zig build -p ~/path/to/output` - Build into the selected install prefix
- `zig build clean` - Remove the install prefix
- `zig build clear` - Remove the install prefix and cached dependencies from `.zig-cache/desk-deps`
- `zig build -Ddesk=~/path/to/desk` - Build, clean the target desk directory, and copy the install prefix into it; supports absolute and relative paths
