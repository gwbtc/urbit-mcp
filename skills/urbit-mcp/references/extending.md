# Extending the MCP server

%mcp-server holds its tools, prompts, resources, and templates in agent
state. You can add features at runtime with the `mcp/add-mcp-*` tools, or
write them as desk files and bulk-load them with `mcp/import-mcp-*`. No
recompile of the agent is needed either way. Notifications of these changes
will come in through MCP `list_changed` notifications.

## Where importable MCP features live

Third-party Urbit apps should follow the same convention as %mcp-server, where
tools, resources, and prompts are made available through these scry paths.

- `/x/mcp/tools` - returns `(list tool:mcp)` or JSON
- `/x/mcp/prompts` - returns `(list promp:mcp)` or JSON
- `/x/mcp/resources` - returns `(list resource:mcp)` or JSON
- `/x/mcp/resource-templates` - returns `(list template:resource:mcp)` or JSON

## Writing a tool

A tool is a tuple: name, description, parameter map, required-parameter
list, and a `$thread-builder` — a Hoon gate that takes the caller's arguments
and returns a Spider thread:

```hoon
$-((map name:parameter:tool:mcp argument:tool:mcp) shed:khan)
```

The function signature can't be more specific than `$shed:khan` because of a
limitation of Arvo. In practice, a `$thread-builder`'s output thread must return a
`$response:tool:mcp`, which is either `[%error @tas (unit json)]` or
a `[%result *]`, where the body of that result is either `[%structured json]`
or `[%unstructured (list result:tool:mcp)]`.

Skeleton (see `/desk/fil/mcp/tools/` for full examples):

```hoon
/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'context/tool-name'
    'What it does.'
    (my ['arg' [%string 'What arg means.']]~)
    ~['arg']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  arg=(unit argument:tool:mcp)  (~(get by args) 'arg')
    ?~  arg  (pure:m !>([%error %missing-arg ~]))
    ?>  ?=([%string @t] u.arg)
    ::  ... do work with strandio (scry, poke, wait, http) ...
    %-  pure:m
    !>  ^-  response:tool:mcp
    [%result %unstructured [%text 'done']~]
==
```

Conventions worth keeping:

- Never crash if avoidable, always return `[%error %some-useful-tag ~]`, where
  `~` is a `(unit json)` in which you can serialize more info like a stack trace
- Wrap crashy work (scries, `+ream`/`+slap` of user Hoon) in `+mule` and turn
  the `$tang` into text so the caller sees the error
- Namespace tool names with a prefix (e.g. `app-name/tool-name`), the
  `mcp/*` and `dojo/*` prefixes should be reserved for %mcp-server
- Read the `mcp/strandio` and `mcp/spider` resources for the thread API

When adding via `mcp/add-mcp-tool`, pass only the gate (from `|=` down) as
the `$thread-builder` string, and the parameters as a JSON object:

```json
{"arg": {"type": "string", "description": "What arg means."}}
```

## Writing a prompt

A prompt is: name, title, description, argument list
(`[name description required?]`), an optional icon list, and a
`$messages-builder`:

```hoon
$-((map name:argument:prompt:mcp @t) (list message:prompt:mcp))
```

Each message is a role plus content; the harness appends them to the
conversation when the user runs the slash command. See
`/desk/fil/mcp/prompts/dojo.hoon` for a minimal example.

## Writing a resource or template

Both are metadata tuples: URI (or URI template), name, then optional title,
description, MIME type, size, and annotations. The server resolves the URI
scheme at read time (`https://`, `beam://`, `scry://`, `fine://` — see
[resources.md](resources.md)). Adding one is usually a single
`mcp/add-mcp-resource` or `mcp/add-mcp-template` call; no Hoon beyond the
URI is needed.

## Testing a new feature

1. If written as a desk file on a third-party desk: `mcp/commit-desk`, then
   the matching `mcp/import-mcp-*` with that desk. Import reads the desk's
   live agents' `/x/mcp/*` scries, so it only picks up what those agents
   already serve — it does not build desk files. On the %mcp desk itself,
   commit with `mcp/commit-desk` (which reports build errors), then register
   the file through `dojo/command`:
   `:mcp-server &add-tool -build-file /=mcp=/fil/mcp/tools/my-tool/hoon`
   (marks `%add-prompt`, `%add-resource`, `%add-template` for the others).
2. If added inline: the `add-mcp-*` tool builds the gate immediately and
   returns any compile error.
3. Call the new tool (or read the new resource) once with harmless
   arguments before telling the user it works.
4. `mcp/tool-search` (`scry://gx/mcp-server/mcp/tools/{+toolPath}/json`)
   confirms what is registered under a name prefix.

## Deleting a feature

No MCP tool deletes a feature; poke the agent through `dojo/command`. Each
poke takes the key as a cord: the name of a tool, prompt or template, or the
URI of a resource.

```
:mcp-server &delete-tool 'my/tool'
:mcp-server &delete-prompt 'my/prompt'
:mcp-server &delete-resource 'https://example.com/doc'
:mcp-server &delete-template 'my/template'
```

A deleted default (one under `/fil/mcp` on the %mcp desk) comes back the next
time the agent loads.
