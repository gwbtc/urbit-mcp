/-  mcp, mcp-proxy, spider
/+  io=strandio, jut=json-utils
^-  tool:mcp
:*  'mcp/add-mcp-server'
    '''
    Add a remote MCP server to %mcp-proxy, or replace the URL and
    headers of one with the same id. %mcp-server then lists the
    remote's tools as <id>/<tool-name>; the list loads in the
    background and refreshes daily. Header values you pass here land
    in this conversation's transcript, so prefer tokens with narrow
    scopes.
    '''
    %-  my
    :~  :-  'id'
        :-  %string
        '''
        Server id, used as the tool name prefix. Must not be empty,
        contain a slash, or be mcp, dojo or aqua.
        '''
        ['url' [%string 'The MCP endpoint URL of the remote server.']]
        :-  'headers'
        :-  %object
        '''
        HTTP headers to send on each request, as an object of
        header name to string value (optional).
        '''
    ==
    ~['id' 'url']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  id=(unit argument:tool:mcp)   (~(get by args) 'id')
    =/  url=(unit argument:tool:mcp)  (~(get by args) 'url')
    =/  hed=(unit argument:tool:mcp)  (~(get by args) 'headers')
    ?.  ?=([~ %string *] id)
      (pure:m !>(`response:tool:mcp`[%error 'Missing id' ~]))
    ?.  ?=([~ %string *] url)
      (pure:m !>(`response:tool:mcp`[%error 'Missing url' ~]))
    =/  headers=(list header:mcp-proxy)
      ?.  ?=([~ %object *] hed)
        ~
      %+  murn  ~(tap by p.u.hed)
      |=  [key=@t val=argument:tool:mcp]
      ^-  (unit header:mcp-proxy)
      ?.  ?=([%string *] val)
        ~
      `[key p.val]
    ;<  ~  bind:m
      %:  poke-our:io
          %mcp-proxy
          %mcp-proxy-action
          !>(`action:mcp-proxy`[%add-mcp-server p.u.id p.u.url headers])
      ==
    ::  wait for the first refresh, which drops our own %mcp-server
    =/  tries=@ud  0
    |-  ^-  form:m
    =*  loop  $
    ;<  ~  bind:m  (sleep:io ~s1)
    ;<  servers=json  bind:m  (scry:io json /gx/mcp-proxy/servers/json)
    =/  mine=(list json)
      ?.  ?=([%a *] servers)  ~
      (skim p.servers |=(s=json =(`s+p.u.id (~(get jo:jut s) /id))))
    ?~  mine
      %-  pure:m
      !>  ^-  response:tool:mcp
      :+  %error
        (crip "Not added: {(trip p.u.url)} is this ship's own MCP endpoint.")
      ~
    =/  tools=(unit json)  (~(get jo:jut i.mine) /tools)
    =/  n=@ud  ?.(?=([~ %a *] tools) 0 (lent p.u.tools))
    ?:  &(=(0 n) (lth tries 35))
      loop(tries +(tries))
    %-  pure:m
    !>  ^-  response:tool:mcp
    :-  %result
    :-  %unstructured
    :_  ~
    :-  %text
    ?:  =(0 n)
      %-  crip
      "Added {(trip p.u.id)}, but it lists no tools yet. If its refresh failed, the ship printed why."
    %-  crip
    "Added {(trip p.u.id)} with {<n>} tools, named {(trip p.u.id)}/<tool-name>."
==
