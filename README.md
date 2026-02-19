# Urbit MCP Server

A general-purpose Model Context Protocol interface for Urbit.

## Developer Setup

### 1. Build and Install

*Requires [peru](https://github.com/buildinspace/peru) package manager.*

```bash
# Clone repository
$ git clone <repo-url>
$ cd urbit-mcp-server

# Install dependencies
$ pip install peru
```

```dojo
::  Create and mount the desk on your Urbit ship
> |new-desk %mcp-server
> |mount %mcp-server
```

```bash
# Install dependencies and copy /dist to your desk
$ ./build.sh -p ~/path/to/ship/mcp-server
```

```dojo
::  commit and install on the ship
> |commit %mcp-server
> |install our %mcp-server
```

### 2. Authentication Setup

Get your ship's web login code:
```
~sampel:dojo> +code
```

Authenticate and get session cookie:

```bash
curl -i http://localhost:8080/~/login -X POST -d "password=your-web-login-code"
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
