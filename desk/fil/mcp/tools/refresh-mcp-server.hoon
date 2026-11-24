/-  mcp, mcp-proxy, spider
/+  io=strandio
^-  tool:mcp
:*  'mcp/refresh-mcp-server'
    '''
    Reload a remote MCP server's tool list in the background. With no
    id, reload every server. If a remote fails, its old list stays.
    '''
    (my ~[['id' [%string 'The server id (optional).']]])
    ~
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  id=(unit argument:tool:mcp)  (~(get by args) 'id')
    =/  which=(unit server-id:mcp-proxy)
      ?.  ?=([~ %string *] id)
        ~
      `p.u.id
    ;<  ~  bind:m
      %:  poke-our:io
          %mcp-proxy
          %mcp-proxy-action
          !>(`action:mcp-proxy`[%refresh-mcp-server which])
      ==
    %-  pure:m
    !>  ^-  response:tool:mcp
    [%result %unstructured ~[[%text 'Refresh started.']]]
==
