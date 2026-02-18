/-  mcp, spider
/+  io=strandio
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
        ['thread-builder' [%string 'A Hoon gate $-((map name:parameter:tool:mcp argument:tool:mcp) ,vase).']]
    ==
    ~['name' 'desc' 'parameters' 'required' 'thread-builder']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  nam=(unit argument:tool:mcp)      (~(get by args) 'name')
    =/  des=(unit argument:tool:mcp)      (~(get by args) 'desc')
    =/  req-arg=(unit argument:tool:mcp)  (~(get by args) 'required')
    =/  ted=(unit argument:tool:mcp)      (~(get by args) 'thread-builder')
    ?~  nam
      ~|(%missing-name !!)
    ?>  ?=([%string @t] u.nam)
    ?~  des
      ~|(%missing-desc !!)
    ?>  ?=([%string @t] u.des)
    ?~  req-arg
      ~|(%missing-required !!)
    ?>  ?=([%array *] u.req-arg)
    ?~  ted
      ~|(%missing-thread-builder !!)
    ?>  ?=([%string @t] u.ted)
    =/  req=(list @t)
      %+  turn  p.u.req-arg
      |=  =argument:tool:mcp
      ?>  ?=([%string @t] argument)
      p.argument
    =/  param-arg=(unit argument:tool:mcp)  (~(get by args) 'parameters')
    ?~  param-arg
      ~|(%missing-parameters !!)
    ?>  ?=([%object *] u.param-arg)
    ::
    ;<  =beak  bind:m  get-beak:io
    =/  par=(map name:parameter:tool:mcp def:parameter:tool:mcp)
      %-  ~(gas by *(map name:parameter:tool:mcp def:parameter:tool:mcp))
      %+  turn
        ~(tap by p.u.param-arg)
      |=  [name=@t =argument:tool:mcp]
      ^-  [name:parameter:tool:mcp def:parameter:tool:mcp]
      ?>  ?=([%object *] argument)
      =/  typ-arg=(unit argument:tool:mcp)   (~(get by p.argument) 'type')
      =/  desc-arg=(unit argument:tool:mcp)  (~(get by p.argument) 'description')
      ?~  typ-arg
        ~|(%missing-parameter-type !!)
      ?>  ?=([%string @t] u.typ-arg)
      ?~  desc-arg
        ~|(%missing-parameter-description !!)
      ?>  ?=([%string @t] u.desc-arg)
      :-  name
      [(type:parameter:tool:mcp p.u.typ-arg) p.u.desc-arg]
    ;<  our=ship  bind:m  get-our:io
    =/  vax=vase
      %+  slap
        !>  :*  mcp=mcp
                spider=spider
                strand=strand:spider
                io=io
                strand-fail=strand-fail:strand:spider
                ..zuse
            ==
      (ream p.u.ted)
    ;<  ~  bind:m
      %-  send-raw-card:io
      :*  %pass   /add-tool
          %agent  [our %mcp-server]
          %poke   %add-tool
          !>([p.u.nam p.u.des par req !<(thread-builder:tool:mcp vax)])
      ==
    ;<  ~  bind:m  (take-poke-ack:io /add-tool)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'Tool added!']
    ==
==
