/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'mcp/add-mcp-tool'
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
    ?~  nam  (pure:m !>([%error %missing-tool-name ~]))
    ?>  ?=([%string @t] u.nam)
    ?~  des  (pure:m !>([%error %missing-tool-description ~]))
    ?>  ?=([%string @t] u.des)
    ?~  req-arg  (pure:m !>([%error %missing-required-tool-parameters ~]))
    ?>  ?=([%array *] u.req-arg)
    ?~  ted  (pure:m !>([%error %missing-tool-thread-builder ~]))
    ?>  ?=([%string @t] u.ted)
    =/  req=(list @t)
      %+  turn  p.u.req-arg
      |=  =argument:tool:mcp
      ?>  ?=([%string @t] argument)
      p.argument
    =/  param-arg=(unit argument:tool:mcp)  (~(get by args) 'parameters')
    ?~  param-arg  (pure:m !>([%error %missing-tool-parameters ~]))
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
    ::  compile once here so a gate that does not build is refused now;
    ::  the agent keeps the TEXT and compiles it again when the tool is
    ::  called (a gate in agent state stops nesting at the next kernel)
    =/  vax=vase
      %+  slap
        !>  :*  mcp=mcp
                spider=spider
                strand=strand:spider
                io=io
                ..zuse
            ==
      (ream p.u.ted)
    =/  built=thread-builder:tool:mcp  !<(thread-builder:tool:mcp vax)
    ;<  ~  bind:m
      %-  send-raw-card:io
      :*  %pass   /add-tool
          %agent  [our %mcp-server]
          %poke   %add-tool
          !>  ^-  [spec:tool:mcp source:mcp]
          [[p.u.nam p.u.des par req] [%hoon p.u.ted]]
      ==
    ;<  ~  bind:m  (take-poke-ack:io /add-tool)
    %-  pure:m
    !>  ^-  response:tool:mcp
    :-  %result
    :-  %unstructured
    :~  [%text 'Tool added!']
    ==
==
