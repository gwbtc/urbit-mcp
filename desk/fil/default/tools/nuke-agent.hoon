/-  mcp, spider
/+  io=strandio, jut=json-utils
^-  tool:mcp
:*  'nuke-agent'
    '''
    Permanently wipe the state of a Gall agent.
    You can also nuke an entire desk.
    '''
    %-  my
    :-  'agent'
    :-  %string
    '''
    Agent to nuke (e.g. 'graph-store' to nuke %graph-store).
    '''
    ~['agent']
    ^-  thread-builder:tool:mcp
    |=  args=(map @t json)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  args-json=json  [%o args]
    =/  agent-name=(unit @t)
      (~(deg jo:jut args-json) /agent so:dejs:format)
    ?~  agent-name  ~|(%missing-agent !!)
    =/  agent=@tas  (@tas u.agent-name)
    ;<  our=@p  bind:m  get-our:io
    ;<  ~  bind:m
      (poke:io [our %hood] %kiln-nuke !>([agent %.y]))
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Agent %{(trip u.agent-name)} nuked")]
    ==
==
