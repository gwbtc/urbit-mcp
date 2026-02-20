---
name: commit-desk
description: Commit an Urbit desk with %mcp-server. Use when user asks to commit changes while working in the git repo for an Urbit project, or asks to commit a specific desk like "commit mcp-server", "commit %mcp-server".
model: "inherit"
---

# Commit changes to a desk in Clay

## Overview

Commit changes to a desk to register them in Clay, Urbit's filesystem.

## Instructions

In a development context, you may be working in a git repo in the Unix filesystem. If so, you'll have to copy the source files into the desk via a normal Unix operation. Check your source repo for build / install instructions in README.md or CLAUDE.md, etc. If there are no such instructions and there's just a `/desk` or `/app`, `/mar`, `/sur` folders in your repo, you can `cp -r` the contents of that `/desk` folder into the Urbit desk.

### Prerequisites

You must know the ship and desk you're working with.

## Error Handling

- If you can't copy files into the desk, it may not be mounted.
  - Check if the desk is mounted by running `ls ~/path/to/ship`, which will list the ship's mounted desks.
  - Use your `mcp__*__mount-desk` tool to mount the target desk.
- If this errors with a timeout, that might not be an issue. In the current implementation (~2026.2.19), this means that there are no changes to commit. This is only a problem if you expect there to be changes.
- If this errors with a stack trace, there's a compile-time issue in the "proposed changes" to the desk. Clay won't accept unsuccessful commits.
- If there's a Gall agent in this desk and the error message contains `load-failed`, it means the Gall agent expects state of one type but is getting state of another type.
  - This happens if you've made changes to the agent's state type without adding a state migration. Ask the user how to proceed. (In development cases, you can use your `mcp__*__nuke-agent` tool to nuke the state of the agent then revive it. This will permanently wipe the agent's state.)

