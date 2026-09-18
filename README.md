# Urbit MCP

A general-purpose Model Context Protocol interface for Urbit.

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
