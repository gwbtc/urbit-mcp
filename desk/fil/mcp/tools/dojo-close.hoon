/-  mcp, spider
/+  io=strandio, dj=mcp-dojo
^-  tool:mcp
:*  'dojo/close'
    '''
    Drop a Dojo session kept open by dojo/command's sole-id parameter,
    along with its variables, and stop any command it is still running.
    '''
    (my ~[['sole-id' [%string 'Session name given to dojo/command.']]])
    ~['sole-id']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  name=(unit argument:tool:mcp)  (~(get by args) 'sole-id')
    ?.  &(?=([~ %string @t] name) (valid-name:dj p.u.name))
      (pure:m !>(`response:tool:mcp`[%error 'invalid sole-id' ~]))
    ;<  ~  bind:m
      (poke-our:io %mcp-server %mcp-dojo !>(`action:dj`[%close p.u.name]))
    (pure:m !>(`response:tool:mcp`[%result %structured (pairs:enjs:format ~[['closed' s+p.u.name]])]))
==
