/-  mcp, spider
/+  io=strandio, at=mcp-aqua-tool
^-  tool:mcp
:*  'aqua/release'
    'Discard a finished run and its retained logs. Cancel active runs first. At most four runs are retained; starting another evicts the oldest finished run.'
    (my ~[['runId' [%string 'Finished run ID to release.']]])
    ~['runId']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  run-id=@ta  (id:at args)
    ;<  ~  bind:m
      (poke-our:io %mcp-server %mcp-aqua !>([%release run-id]))
    (pure:m !>([%result %structured (pairs:enjs:format ~[['runId' s+run-id] ['released' b+&]])]))
==
