# Urbit MCP

A general-purpose Model Context Protocol interface for Urbit.

## Developer Setup

### 1. Build and Install

- *Requires a running [Urbit](https://docs.urbit.org/get-on-urbit) ship, real or fake, running on a machine you have terminal access to.*
- *Requires [peru](https://github.com/buildinspace/peru) package manager. Install and set that up if you don't have it already. Make sure `peru --version` works.*

Create and mount the desk on your Urbit ship:

```dojo
> |new-desk %mcp
> |mount %mcp
```

In the `urbit-mcp` folder, run the [build script](build.sh). By default this will install dependencies into `/dist` in this folder. Use the `-p` argument to additionally copy the %mcp source and its dependencies into your ship's desk. This script will take a minute if it's your first time running it.

```bash
$ cd urbit-mcp
$ build.sh -p ~/path/to/zod/mcp
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

### 3A. Register with Claude

Add the MCP server to Claude using HTTP transport:

```bash
claude mcp add --transport http zod http://localhost:80/mcp --header "Cookie: urbauth-~your-ship=0v3.j2062.1prp1.qne4e.goq3h.ksudm" --scope user
```
### 3B. Register with Codex

Codex requires the `mcp-proxy` python package to function. Install with `uvx mcp-proxy`, then append this to your `~/.codex/config.toml`:

```toml
[mcp_servers.fen]
command = "uvx"
args = [
  "mcp-proxy",
  "--transport", "streamablehttp",
  "--headers", "Cookie", "urbauth-~your-ship=0v2.20fhu.t7ki1.cftjr.3s8bv.d9i5l",
  "http://localhost:80/mcp"
]
```

## Usage

### Tools

Just ask! You can see the default tools [here](./desk/fil/default/mcp/tools).

You can ask your LLM to add new Tools. Give it a description (and ideally, examples) and it will do its best, or provide a Hoon thread for it to adapt to run in `%mcp-server`. Threads in `%mcp-server` must be of signature `$-((map @t argument:tool:mcp) shed:khan)`.

### Prompts (slash commands)

MCP prompts for most default tools are available as slash commands, using the format `/mcp__<mcp server>__<tool name>`.

```
/mcp__zod__commit-desk mcp
```

Running these will append a predefined prompt to the conversation and call out to the LLM provider.

Type `/` in Claude Code to see available Prompts.

You can ask your LLM to add new Prompts. These can be any reusable snippet of text you like.

### Resources (@ mentions)

MCP resources can be referenced with an `@` mention to pull the contents into the context window.

```
@zod:https://docs.urbit.org/llms.txt
```

Type `@` in Claude Code to see available Resources.

You can ask your LLM to add new Resources by providing an `https://` URI to a public webpage or a `beam://` URI to a file in Clay.

## Contributing

This repo requires commits to be signed with a [Groundwire](https://groundwire.network) identity. PRs with unsigned commits will be rejected by CI.

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

- `./build.sh` - Build full desk
- `./build.sh build-dev` - Build dependencies
- `./build.sh clean` - Clean build directories
- `./build.sh -p /path/to/desk` - Build and copy to a ship's desk
