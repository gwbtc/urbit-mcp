/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'revive-agent'
    '''
    Revive (re-initialize) a nuked Gall agent on this ship.
    You can also revive an entire desk.
    '''
    %-  my
    :~  :-  'agent'
        :-  %string
        '''
        Desk name to revive (e.g. 'hark' to revive %hark).
        '''
    ==
    ~['agent']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  agent=(unit argument:tool:mcp)
      (~(get by args) 'agent')
    ?~  agent
      ~|(%missing-agent !!)
    ?>  ?=([%string @t] u.agent)
    ;<  our=@p  bind:m  get-our:io
    ;<  ~  bind:m
      (poke:io [our %hood] %kiln-revive !>((@tas p.u.agent)))
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Agent %{(trip p.u.agent)} revived successfully")]
    ==
==
