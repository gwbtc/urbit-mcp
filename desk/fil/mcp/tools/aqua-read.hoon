/-  mcp, spider
/+  io=strandio, aq=mcp-aqua, at=mcp-aqua-tool
^-  tool:mcp
:*  'aqua/read'
    '''
    Read one page of output captured from a managed Aqua run. The result
    holds the run's status, a list of records (cursor, ship, effect, type,
    text, observedAt, elapsedMs, truncated), and nextCursor. Pass nextCursor
    as cursor on the next read. hasMore counts buffered records only; the
    thread is done when status is completed, failed, cancelled, or
    interrupted.
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
