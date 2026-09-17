/-  mcp, spider
/+  io=strandio, aq=mcp-aqua, at=mcp-aqua-tool
^-  tool:mcp
:*  'aqua/cancel'
    'Stop the managed Spider thread and its descendants. Does not kill the shared Aqua agent or its virtual ships. Read until status is cancelled.'
    (my ~[['runId' [%string 'Run ID returned by aqua/start.']]])
    ~['runId']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  run-id=@ta  (id:at args)
    ;<  ~  bind:m
      (poke-our:io %mcp-server %mcp-aqua !>([%cancel run-id]))
    =/  encoded=@ta  (scot %uv (jam `query:aq`[run-id 0 ~ ~ | 8.192]))
    ;<  result=json  bind:m
      (scry:io json %gx /mcp-server/aqua/read/[encoded]/json)
    (pure:m !>([%result %structured result]))
==
