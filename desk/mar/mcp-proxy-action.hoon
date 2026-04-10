/-  mcp-proxy
|_  act=action:mcp-proxy
++  grow
  |%
  ++  noun  act
  --
++  grab
  |%
  ++  noun  action:mcp-proxy
  ++  json
    |=  jon=^json
    ^-  action:mcp-proxy
    =,  dejs:format
    =/  typ=@t  ((ot ~[action+so]) jon)
    =/  get-opt-tas
      |=  key=@t
      ^-  (unit @tas)
      ?.  ?=(%o -.jon)  ~
      =/  v=(unit ^json)  (~(get by p.jon) key)
      ?~  v  ~
      ?.  ?=(%s -.u.v)  ~
      ?:  =('' p.u.v)  ~
      ``@tas`p.u.v
    =/  get-opt-str
      |=  key=@t
      ^-  (unit @t)
      ?.  ?=(%o -.jon)  ~
      =/  v=(unit ^json)  (~(get by p.jon) key)
      ?~  v  ~
      ?.  ?=(%s -.u.v)  ~
      ?:  =('' p.u.v)  ~
      `p.u.v
    =/  get-str
      |=  key=@t
      ^-  @t
      ?.  ?=(%o -.jon)  ''
      =/  v=(unit ^json)  (~(get by p.jon) key)
      ?~  v  ''
      ?.  ?=(%s -.u.v)  ''
      p.u.v
    =/  get-mode
      ^-  server-mode:mcp-proxy
      ?:  =('openapi' (get-str 'mode'))  %openapi  %proxy
    ?+  typ  !!
        %'add-server'
      =/  f
        %-  ot
        :~  id+so  name+so  url+so
            headers+(ar (ot ~[key+so value+so]))
        ==
      =/  [id=@t name=@t url=@t headers=(list header:mcp-proxy)]  (f jon)
      [%add-server `@tas`id [name url headers %.y (get-opt-tas 'oauth-provider') get-mode (get-opt-str 'schema-url')]]
    ::
        %'remove-server'
      [%remove-server `@tas`((ot ~[id+so]) jon)]
    ::
        %'update-server'
      =/  f
        %-  ot
        :~  id+so  name+so  url+so
            headers+(ar (ot ~[key+so value+so]))
            enabled+bo
        ==
      =/  [id=@t name=@t url=@t headers=(list header:mcp-proxy) enabled=?]  (f jon)
      [%update-server `@tas`id [name url headers enabled (get-opt-tas 'oauth-provider') get-mode (get-opt-str 'schema-url')]]
    ::
        %'toggle-server'
      [%toggle-server `@tas`((ot ~[id+so]) jon)]
    ::
        %'refresh-spec'
      [%refresh-spec `@tas`((ot ~[id+so]) jon)]
    ::
        %'set-tool-filter'
      [%set-tool-filter `@tas`((ot ~[id+so]) jon) [%block ~]]
    ::
        %'clear-tool-filter'
      [%clear-tool-filter `@tas`((ot ~[id+so]) jon)]
    ::
        %'login-server'
      [%login-server `@tas`((ot ~[id+so]) jon)]
    ::
        %'set-client-key'
      [%set-client-key ((ot ~[key+so]) jon)]
    ::
        %'regenerate-client-key'
      [%regenerate-client-key ~]
    ::
        %'clear-client-key'
      [%clear-client-key ~]
    ::
        %'set-internal-token'
      [%set-internal-token ((ot ~[token+so]) jon)]
    ==
  --
++  grad  %noun
--
