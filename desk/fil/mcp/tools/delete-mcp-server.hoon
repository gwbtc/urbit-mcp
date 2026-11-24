/-  mcp, mcp-proxy, spider
/+  io=strandio
^-  tool:mcp
:*  'mcp/delete-mcp-server'
    '''
    Remove a remote MCP server from %mcp-proxy. Its blocked tools
    stay blocked if the server is added again.
    '''
    (my ~[['id' [%string 'The server id.']]])
    ~['id']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  id=(unit argument:tool:mcp)  (~(get by args) 'id')
    ?.  ?=([~ %string *] id)
      (pure:m !>(`response:tool:mcp`[%error 'Missing id' ~]))
    ;<  ~  bind:m
      %:  poke-our:io
          %mcp-proxy
          %mcp-proxy-action
          !>(`action:mcp-proxy`[%delete-mcp-server p.u.id])
      ==
    %-  pure:m
    !>  ^-  response:tool:mcp
    [%result %unstructured ~[[%text (crip "Deleted {(trip p.u.id)}.")]]]
==
