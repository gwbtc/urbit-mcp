/-  mcp, spider
/+  io=strandio, aq=mcp-aqua, at=mcp-aqua-tool
^-  tool:mcp
:*  'aqua/read'
    '''
    Read a bounded JSON page from a managed Aqua run. nextCursor is exclusive;
    filtered-out records advance it too. Reuse a prior cursor to re-filter.
    gap reports evicted records. Only captured effect tags are available.
    observedAt/elapsedMs describe host receipt time, not guest virtual time.
    starting/running/cancelling/finishing are nonterminal. finishing drains
    pending effects before completed/failed/cancelled/interrupted is reported.
    hasMore refers to buffered pages, not whether the thread is finished.
    '''
    %-  my
    :~  ['runId' [%string 'Run ID returned by aqua/start.']]
        ['cursor' [%number 'Start cursor; default 0.']]
        ['ships' [%array 'Optional full Urbit ship identities to include.']]
        ['effects' [%array 'Optional effect tags to include; omitted includes all captured tags.']]
        ['includePrompts' [%boolean 'Include terminal prompt records; default false.']]
        ['maxBytes' [%number 'Serialized JSON budget; clamped to 8192..32768 bytes.']]
    ==
    ~['runId']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  q=query:aq  (query:at args)
    =/  encoded=@ta  (scot %uv (jam q))
    ;<  result=json  bind:m
      (scry:io json %gx /mcp-server/aqua/read/[encoded]/json)
    (pure:m !>([%result %structured result]))
==
