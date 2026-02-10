/-  mcp, spider
/+  io=strandio, jut=json-utils
^-  tool:mcp
:*  'revive-agent'
    '''
    Revive (re-initialize) a nuked Gall agent on this ship.
    You can also revive an entire desk.
    '''
    %-  my
    :-  'agent'
    :-  %string
    '''
    Desk name to revive (e.g. 'hark' to revive %hark).
    '''
    ~['desk']
    ^-  thread-builder:tool:mcp
    |=  args=(map @t json)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  args-json=json  [%o args]
    =/  agent-name=(unit @t)
      (~(deg jo:jut args-json) /desk so:dejs:format)
    ?~  agent-name  ~|(%missing-agent !!)
    =/  desk=@tas  (@tas u.agent-name)
    ;<  our=@p  bind:m  get-our:io
    ;<  ~  bind:m
      (poke:io [our %hood] %kiln-revive !>(desk))
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Agent %{(trip u.agent-name)} revived successfully")]
    ==
==
