---
name: mount-desk
description: Mount a Clay desk on an Urbit ship. Use when the user asks to mount a desk, or when another operation fails because a desk isn't mounted (e.g. you can't find it on the Unix filesystem) e.g. "mount the base desk", "mount %my-app".
description: Mount a Clay desk on the Urbit ship to the host filesystem. Use when the user asks to mount a desk, when you can't find a desk you expected, or if you need to copy files from a source repo to the desk.
model: "inherit"
---

# Mount a desk to the Unix filesystem

## Overview

"Mounting" a Clay desk exposes it to the host machine's Unix filesystem, making it accessible to regular Unix operations like `cp`, `ls`, etc. This is required in a development context where you want to sync a number of files from the source repo to the ship's desk.

## Prerequisites

You must know the desk name (e.g. `mcp-server`, not `%mcp-server`).

## Instructions

Once you've mounted, you can use `ls ~/path/to/ship` to check the desk is exposed as a Unix folder.

*Do not* use `mcp__*__insert-file` to move multiple files from source to the desk.

## Error Handling

- If the desk doesn't exist, you'll need to create it first with `mcp__*__new-desk`.
- To check whether a desk is already mounted, run `ls` on the ship's directory (e.g. `ls ~/path/to/ship/`) and see if the desk appears there.
