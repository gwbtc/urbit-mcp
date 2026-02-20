---
name: poke-our-agent
description: Poke a Gall agent on our Urbit ship. Use when the user asks you to send a poke, trigger some stateful action on their ship, or interact with an app on their Urbit. If this is a scry or read-only request, try the mcp__*__scry tool first.
model: "inherit"
---

# Poke a Gall agent

## Overview

Send a one-way message ("poke") to a running Gall agent on the user's ship. This is the primary way to trigger actions or deliver data to an agent.

## Prerequisites

You must know:
- The agent name
- The desk this agent belongs to
- The mark of the data that you're sending to this agent
  - That the mark is present in the desk and accepted in the agent's `+on-poke` arm.

## Instructions

If you don't know exactly what marks and data this agent takes, use your `mcp__*__get-file` tool to find the agent in `/<desk>/app/<agent>/hoon`. Look at the `+on-poke` arm, likely where it switches on the `mark` type. If marks aren't described there, use `mcp__*__list-files` to list the files in `/[desk]/sur` and look for the relevant type definition in there.

Urbit often uses `$vase`s to send statically-typed data across transaction boundaries. The `mcp__*__poke-our-agent` tool creates a vase of your data, which the agent will attempt to de-vase using its copy of the given mark. Your vase will be created by evaluating your data as a Hoon expression against your Urbit OS kernel (`..zuse`), which limits what you can do with dependencies and named variables in this Hoon data.

## Error Handling

- If the agent isn't running yet, the poke will be queued until it is.
- If the data can't be de-vased through the given mark by the target agent, this poke will fail.
- If your poke is successful, you will only receive an acknowledgement that the poke was successful. Gall is not a request/response framework and this tool doesn't watch for an update from the agent.

