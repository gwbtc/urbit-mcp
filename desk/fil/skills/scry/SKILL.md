---
name: scry
description: Run a scry (read-only request) against a Gall agent on the user's Urbit ship. Use when the user asks to read data from the ship or inspect the state of an app.
model: "inherit"
---

# Scry a Gall agent

## Overview

A scry is a pure, synchronous read from Urbit. This tool is currently (~2026.2.19) limited to scrying endpoints in Gall agents, as defined in their `+on-peek` arms, or vane scries that include a desk in the path. This tool is also currently limited to scrying paths which return JSON.

## Prerequisites

You must know the scry path. The path format is:

```
/[vane letter][care]/[desk]/[path]/[mark]
```

- **Vane letter:** one letter identifying the vane, e.g. `g` for Gall, `c` for Clay, `a` for Ames, etc.
- **Care:** a letter identifying what kind of read to perform, e.g. `x` for a data read, `y` for an `$arch` (directory listing)
- **Desk:** the desk (e.g. `base`, `mcp-server`)
- **Path:** the path to some endpoint, either a 1) `+on-peek` path, 2) file, or 3) Arvo vane endpoint
  - If this is a file the path must end in a mark / file extension
  - With this tool the mark needn't be `/json` as long as it can be converted to JSON (check its `/[desk]/mar/[mark]/hoon` file)
- **Mark:** the mark to return the data as
 - This tool will fill in `%json` as the mark

### Example scry paths

```
/gx/mcp-server/tools/json  :: list tools registered in %mcp-server
/cx/base/sys/kelvin        :: read the kelvin version file from %base
/cy/base/app               :: list files in /app on %base (arch)
```

## Error Handling

- If this fails with a mark conversion error, the endpoint's desk doesn't have a mark file converting its native mark to JSON. Try a different mark at the end of the path, or find the native mark for this endpoint.
- Scries are read-only. If you need to trigger an action or write data, use `mcp__*__poke-agent` instead.

## Resources

- [Ames Scry Reference](https://docs.urbit.org/urbit-os/kernel/ames/scry.md)
- [Behn Scry Reference](https://docs.urbit.org/urbit-os/kernel/behn/scry.md)
- [Clay Scry Reference](https://docs.urbit.org/urbit-os/kernel/clay/scry.md)
- [Dill Scry Reference](https://docs.urbit.org/urbit-os/kernel/dill/scry.md)
- [Eyre Scry Reference](https://docs.urbit.org/urbit-os/kernel/eyre/scry.md)
- [Gall Scry Reference](https://docs.urbit.org/urbit-os/kernel/gall/scry.md)
- [Jael Scry Reference](https://docs.urbit.org/urbit-os/kernel/jael/scry.md)
- [Lick Scry Reference](https://docs.urbit.org/urbit-os/kernel/lick/scry.md)
- [App School I - 10. Scries](https://docs.urbit.org/build-on-urbit/app-school/10-scry.md)

