/-  mcp, spider
/+  io=strandio, jut=json-utils
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'add-mcp-tool'
    '''
    Add a new MCP Tool to the %mcp-server agent state.
    '''
    %-  my
    :~  ['name' [%string 'The name of your MCP tool.']]
        ['desc' [%string 'The description of your MCP tool.']]
        ['parameters' [%object 'The parameters your MCP tool will take.']]
        ['required' [%array 'The non-optional parameters your MCP tool needs.']]
        ::  XX explain helper cores for reusable functions
        ::  XX explain what's available in the subject
        ['thread-builder' [%string 'A Hoon gate $-((map @t json) ,vase).']]
    ==
    ~['name' 'desc' 'parameters' 'required' 'thread-builder']
    ^-  thread-builder:tool:mcp
    |=  args=(map @t json)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  args-json=json
      [%o args]
    =/  nam=(unit @t)         (~(deg jo:jut args-json) /name so:dejs:format)
    =/  des=(unit @t)         (~(deg jo:jut args-json) /desc so:dejs:format)
    =/  req=(unit (list @t))  (~(deg jo:jut args-json) /required (ar so):dejs:format)
    =/  ted=(unit @t)         (~(deg jo:jut args-json) /thread-builder so:dejs:format)
    ?~  nam  ~|(%missing-name !!)
    ?~  des  ~|(%missing-desc !!)
    ?~  req  ~|(%missing-required !!)
    ?~  ted  ~|(%missing-thread-builder !!)
    =/  parameters=(unit (map @t json))
      ?~  param-json=(~(get jo:jut args-json) /parameters)
        ~
      ?.  ?=([%o *] u.param-json)
        ~
      `p.u.param-json
    ?~  parameters
      ~|(%missing-parameters !!)
    ::
    ;<  =beak  bind:m  get-beak:io
    =/  par=(map name:parameter:tool:mcp def:parameter:tool:mcp)
      %-  ~(gas by *(map name:parameter:tool:mcp def:parameter:tool:mcp))
      %+  turn
        ~(tap by u.parameters)
      |=  [name=@t =json]
      ^-  [name:parameter:tool:mcp def:parameter:tool:mcp]
      ?.  ?=([%o *] json)
        ~|(%invalid-parameter-definition !!)
      =/  typ=(unit @t)  (~(deg jo:jut json) /type so:dejs:format)
      =/  dec=(unit @t)  (~(deg jo:jut json) /description so:dejs:format)
      :-  name
      ?~  typ
        ~|(%missing-parameter-type !!)
      ?~  dec
        ~|(%missing-parameter-description !!)
      [(type:parameter:tool:mcp u.typ) u.dec]
    ;<  our=ship  bind:m  get-our:io
    =/  vax=vase
      %+  slap
        !>  :*  mcp=mcp
                spider=spider
                strand=strand:spider
                io=io
                jut=jut
                strand-fail=strand-fail:strand:spider
                ..zuse
            ==
      (ream u.ted)
    ;<  ~  bind:m
      %-  send-raw-card:io
      :*  %pass   /add-tool
          %agent  [our %mcp-server]
          %poke   %add-mcp-tool
          !>([u.nam u.des par u.req !<(thread-builder:tool:mcp vax)])
      ==
    ;<  ~  bind:m  (take-poke-ack:io /add-tool)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'Tool added!']
    ==
==
