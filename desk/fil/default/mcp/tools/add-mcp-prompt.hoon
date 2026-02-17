/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'add-mcp-prompt'
    '''
    Add a new MCP Prompt to the %mcp-server agent state.
    '''
    %-  my
    :~  ['name' [%string 'The name of your MCP prompt.']]
        ['title' [%string 'The title of your MCP prompt.']]
        ['desc' [%string 'The description of your MCP prompt.']]
        ['arguments' [%array 'The arguments your MCP prompt will take. (Optional.)']]
        ['messages-builder' [%string 'A Hoon gate of signature $-((map name:argument:prompt:mcp @t) (list message:prompt:mcp)).']]
    ==
    ~['name' 'title' 'desc' 'messages-builder']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  nam=(unit argument:tool:mcp)          (~(get by args) 'name')
    =/  tit=(unit argument:tool:mcp)          (~(get by args) 'title')
    =/  des=(unit argument:tool:mcp)          (~(get by args) 'desc')
    =/  prompt-args=(unit argument:tool:mcp)  (~(get by args) 'arguments')
    =/  msg=(unit argument:tool:mcp)          (~(get by args) 'messages-builder')
    ?~  nam
      ~|(%missing-name !!)
    ?>  ?=([%string @t] u.nam)
    ?~  tit
      ~|(%missing-title !!)
    ?>  ?=([%string @t] u.tit)
    ?~  des
      ~|(%missing-desc !!)
    ?>  ?=([%string @t] u.des)
    ?~  msg
      ~|(%missing-messages-builder !!)
    ?>  ?=([%string @t] u.msg)
    =/  arguments=(list argument:prompt:mcp)
      ?~  prompt-args
        *(list argument:prompt:mcp)
      ?>  ?=([%array *] u.prompt-args)
      %+  turn
        p.u.prompt-args
      |=  =argument:tool:mcp
      ^-  argument:prompt:mcp
      ?>  ?=([%object *] argument)
      =/  arg-name=(unit argument:tool:mcp)  (~(get by p.argument) 'name')
      =/  arg-desc=(unit argument:tool:mcp)  (~(get by p.argument) 'description')
      =/  arg-req=(unit argument:tool:mcp)   (~(get by p.argument) 'required')
      ?~  arg-name
        ~|(%missing-argument-name !!)
      ?>  ?=([%string @t] u.arg-name)
      ?~  arg-desc
        ~|(%missing-argument-description !!)
      ?>  ?=([%string @t] u.arg-desc)
      ?~  arg-req
        ~|(%missing-argument-required !!)
      ?>  ?=([%boolean ?] u.arg-req)
      [p.u.arg-name p.u.arg-desc p.u.arg-req]
    ::
    =/  vax=vase
      %+  slap
        !>  :*  mcp=mcp
                spider=spider
                strand=strand:spider
                io=io
                strand-fail=strand-fail:strand:spider
                ..zuse
            ==
      (ream p.u.msg)
    ;<  =bowl:rand  bind:m  get-bowl:io
    ;<  ~  bind:m
      %-  send-raw-card:io
      :*  %pass   /add-prompt
          %agent  [our.bowl %mcp-server]
          %poke   %add-prompt
          !>  ^-  prompt:mcp
          :*  p.u.nam
              p.u.tit
              p.u.des
              arguments
              ~
              !<(_messages-builder:*prompt:mcp vax)
          ==
      ==
    ;<  ~  bind:m  (take-poke-ack:io /add-prompt)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'Prompt added!']
    ==
==
