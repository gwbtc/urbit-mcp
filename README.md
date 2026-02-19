# Urbit MCP Server

A general-purpose Model Context Protocol interface for Urbit.

## Developer Setup

### 1. Build and Install

*Requires [peru](https://github.com/buildinspace/peru) package manager. Install and set that up if you don't have it already. Make sure `peru --version` works.*

Create and mount the desk on your Urbit ship:

```dojo
> |new-desk %mcp-server
> |mount %mcp-server
```

In the `urbit-mcp-server` folder, run the [build script](build.sh). By default this will install dependencies into `/dist` in this folder. Use the `-p` argument to additionally copy the %mcp-server source and its dependencies into your ship's desk. This script will take a minute if it's your first time running it.

```bash
$ cd urbit-mcp-server
$ build.sh -p ~/path/to/zod/mcp-server
```

```dojo
> |commit %mcp-server
> |install our %mcp-server
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

### 3. Register with Claude

Add the MCP server to Claude using HTTP transport:

```bash
claude mcp add --transport http zod http://localhost:80/apps/mcp-server/api --header "Cookie: urbauth-~your-ship=0v3.j2062.1prp1.qne4e.goq3h.ksudm"
```

## Development

### Build Commands

- `./build.sh` - Build full desk
- `./build.sh build-dev` - Build dependencies
- `./build.sh clean` - Clean build directories
- `./build.sh -p /path/to/desk` - Build and copy to a ship's desk
