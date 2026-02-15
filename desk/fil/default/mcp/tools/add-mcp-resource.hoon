/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'add-mcp-resource'
    '''
    Add a new MCP Resource to the %mcp-server agent state.
    '''
    %-  my
    :~  ['uri' [%string 'The URI of your MCP resource.']]
        ['name' [%string 'The name of your MCP resource.']]
        ['desc' [%string 'The description of your MCP resource.']]
        ['mime-type' [%string 'The MIME type of your MCP resource (optional).']]
        ['audience' [%array 'The audience list for your MCP resource (optional).']]
    ==
    ~['uri' 'name' 'desc']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  uri=(unit argument:tool:mcp)   (~(get by args) 'uri')
    =/  nam=(unit argument:tool:mcp)   (~(get by args) 'name')
    =/  des=(unit argument:tool:mcp)   (~(get by args) 'desc')
    =/  mime=(unit argument:tool:mcp)  (~(get by args) 'mime-type')
    =/  aud=(unit argument:tool:mcp)   (~(get by args) 'audience')
    ?~  uri
      ~|(%missing-uri !!)
    ?>  ?=([%string @t] u.uri)
    ?~  nam
      ~|(%missing-name !!)
    ?>  ?=([%string @t] u.nam)
    ?~  des
      ~|(%missing-desc !!)
    ?>  ?=([%string @t] u.des)
    =/  mime-type=(unit @t)
      ?~  mime
        ~
      ?>  ?=([%string @t] u.mime)
      `p.u.mime
    =/  audience=(list @t)
      ?~  aud
        ~
      ?>  ?=([%array *] u.aud)
      %+  turn  p.u.aud
      |=  =argument:tool:mcp
      ?>  ?=([%string @t] argument)
      p.argument
    =/  annotations=(unit annotations:resource:mcp)
      ?:  =(~ audience)
        ~
      `[audience ~ ~]
    ::
    ;<  =bowl:rand  bind:m  get-bowl:io
    ;<  ~  bind:m
      %-  send-raw-card:io
      :*  %pass   /add-resource
          %agent  [our.bowl %mcp-server]
          %poke   %add-resource
          !>([p.u.uri p.u.nam p.u.des mime-type annotations])
      ==
    ;<  ~  bind:m  (take-poke-ack:io /add-resource)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'Resource added!']
    ==
==
