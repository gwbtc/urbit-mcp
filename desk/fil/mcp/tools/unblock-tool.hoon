/-  mcp, mcp-proxy, spider
/+  io=strandio
^-  tool:mcp
:*  'mcp/unblock-tool'
    '''
    Show a tool that mcp/block-tool hid.
    '''
    %-  my
    :~  :-  'tool'
        :-  %string
        '''
        The full tool name, as tools/list shows it: mcp/commit-desk
        or linear/create-issue.
        '''
        :-  'server'
        :-  %string
        '''
        The remote server id. Leave it out for this ship's own tools.
        '''
    ==
    ~['tool']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  tool=(unit argument:tool:mcp)  (~(get by args) 'tool')
    =/  srv=(unit argument:tool:mcp)   (~(get by args) 'server')
    ?.  ?=([~ %string *] tool)
      (pure:m !>(`response:tool:mcp`[%error 'Missing tool' ~]))
    ;<  our=ship  bind:m  get-our:io
    =/  id=server-id:mcp-proxy
      ?.  ?=([~ %string *] srv)
        (local-key:mcp-proxy our)
      p.u.srv
    ;<  ~  bind:m
      %:  poke-our:io
          %mcp-proxy
          %mcp-proxy-action
          !>(`action:mcp-proxy`[%unblock-tool id p.u.tool])
      ==
    %-  pure:m
    !>  ^-  response:tool:mcp
    [%result %unstructured ~[[%text (crip "Unblocked {(trip p.u.tool)}.")]]]
==
