---
name: insert-file
description: Insert / write a file into a Clay desk on an Urbit ship. Use when the user asks you to write a file to a desk, create a new Hoon file on the ship, or copy content into Clay.
model: "inherit"
---

# Insert a file into Clay

## Overview

Write a file into Clay, Urbit's filesystem. The file will be inserted at the specified path, using the filetype ("mark") at the end of the path. This will overwrite files with the same path.

## Prerequisites

You must know:
- The desk the user wants to insert the file in
- The name of the file you're inserting / which the user wants you to insert
- The content of the file
- The desired filetype of this file
- That the target desk has a `/<desk>/mar/<mark>.hoon` mark file corresponding to the desired filetype.

Since this is going through the %mcp-server and not the Unix filesystem, the target desk needn't be mounted.

## Instructions

Once you've inserted a file, you are *almost always* going to want to use the `mcp__*__commit-desk` tool to register this change in the Clay filesystem.

## Error Handling

- If the insert fails because the mark is unknown, the desk is missing a mark file at `/<desk>/mar/<mark>.hoon`.
  - The desk must define that mark before files of that type can be inserted.
  - If you're in a development context, defer to the user as to how to get the mark.
- If `mcp__*__commit-desk` fails with a compile-time error, there might be something wrong with your file or the chosen mark. Look at the `commit-desk` skill for advice.

