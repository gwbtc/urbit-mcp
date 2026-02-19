/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'nuke-agent'
    '''
    Permanently wipe the state of a Gall agent.
    You can also nuke an entire desk.
    '''
    %-  my
    :~  :-  'agent'
        :-  %string
        '''
        Gall agent to nuke (e.g. 'graph-store' to nuke %graph-store).
        '''
    ==
    ~['agent']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  agent=(unit argument:tool:mcp)  (~(get by args) 'agent')
    ?~  agent
      ~|(%missing-agent !!)
    ?>  ?=([%string @t] u.agent)
    ;<  ~  bind:m
      (poke-our:io %hood %kiln-nuke !>([(@tas p.u.agent) %.y]))
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Nuked %{(trip p.u.agent)}")]
    ==
==
