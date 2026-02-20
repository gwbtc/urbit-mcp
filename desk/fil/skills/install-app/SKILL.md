---
name: install-app
description: Install a desk (app) on an Urbit ship. Use when the user asks you to install an app or desk, e.g. "install mcp-server", "install ~zod %app". Also use when you've just created a new desk and need to start its Gall agents running on the ship.
model: "inherit"
---

# Install an app (desk) on an Urbit ship

## Overview

Install a desk, starting its Gall agents and listening for updates from the given ship.

## Prerequisites

You must know:
- The desk name to install (e.g. `mcp-server`, not `%mcp-server`)
- Optionally, the ship to install from (e.g. `~zod`, defaults to the local ship)

## Instructions

### Local apps

In a development context, you must install a local desk you've newly created (with `mcp__*__new-desk`) and committed to (`mcp__*__commit-desk`) to start its Gall agents. If the desk was successfully committed, there shouldn't be an error here.

### Remote apps

If the desk is on another ship, this tool may fail. In the current implementation ~(2026.2.19), this tool just tells you that the poke to install the desk has been sent. It doesn't tell you when the app is installed, or if the app can be installed at all. In general, remote installs take at least a few minutes. If this ship/desk is unreachable at the time you install, it will be installed if it ever becomes available again.

