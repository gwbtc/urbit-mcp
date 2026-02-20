---
name: get-file
description: Get a Clay file (local or remote) using Urbit %mcp-server. Use when the user asks you to look at a file like /~zod/base/~2026.2.9..13.43.05..97c0/sys/kelvin, or asks to get a specific file from an Urbit ship. Use when the user mentions "clay file", "get this file from ~sampel-palnet", etc.
model: "inherit"
---

# Get a Clay file

## Overview

Read the text of a local or remote file from Clay by its `beam://` URI. Will fail if you try to read a directory.

### Prerequisites

You must know the ship, desk, and path to get. This tool has an optional fourth argument, the `case` which will default to the current datetime.

If you don't know the ship and desk, you may substitute `=` for these two arguments, and the tool will dereference them to the user's ship and the `%base` desk respectively.

### Instructions

A `$beam` is Clay's internal representation of a `$path`.

```dojo
> (de-beam /~zod/base/~2026.2.9..13.44.04..cb83/sys/kelvin)
[~ [[p=~zod q=%base r=[%da p=~2026.2.9..13.44.04..cb83]] s=/sys/kelvin]]
````

```dojo
> (en-beam [[p=~zod q=%base r=[%da p=~2026.2.9..13.43.05..97c0]] s=/sys/kelvin])
/~zod/base/~2026.2.9..13.43.05..97c0/sys/kelvin
```

The %mcp-server introduces a `beam://` URI scheme which enables the Dojo convention of stubbing out one or all of the first three path segments with a `=`.

```
beam://~zod/base/~2026.2.9..13.44.04..cb83/sys/kelvin
beam://~zod/base/=/sys/kelvin
beam://~zod/=/=/sys/kelvin
beam://=/=/=/sys/kelvin
beam://===/sys/kelvin
```

The %mcp-server will catch requests for a `beam://` resource and dereference `=` values to their appropriate default.

Unlike scries, `$beam`s are globally-unique (not temporally unique), absolute paths to static files. They do not allow for mark conversion.

Look at the reference material for more info on these types, including the `$case` types `[%da @da]` (datetime), `[%ud @ud]` (revision number), and `[%uv @uv]` (content hash).

## Error Handling

### Local files

- Check that your inputs are correct:
  - The `ship` must be `=` or a valid Urbit ID like `~zod`
  - The `desk` must be `=` or a desk name like `base`, not `%base`
  - The `path` must begin with `/` and end with a filetype (a "mark" in Urbit parlance)

### Global files

- The ship might not be online, or we might not have a connection to it.
- You might not have permission to read this file.

## Resources

- `$beam` documentation: https://docs.urbit.org/urbit-os/kernel/clay/data-types.md#beam
- `$case` documentation: https://docs.urbit.org/urbit-os/kernel/clay/data-types#case

