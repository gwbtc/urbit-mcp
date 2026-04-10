::  mcp-proxy: proxy for remote MCP servers
::
::    configure remote MCP server endpoints via the web UI.
::    point an LLM at /apps/mcp/mcp for an aggregate endpoint
::    that combines tools from all configured servers.
::    or /apps/mcp/mcp/{server-id} for a single server.
::
/-  mcp-proxy
/-  oauth
/+  default-agent, dbug, server
|%
+$  card  card:agent:gall
::
+$  agg-request
  $:  eyre-id=@ta
      req-id=json
      method=@t
      total=@ud
      results=(map server-id:mcp-proxy (unit json))
  ==
--
::
%-  agent:dbug
=|  state-4:mcp-proxy
=*  state  -
=/  pending  *(map @t @ta)
=/  wrap-set  *(map @t json)                      ::  wire-id -> client's JSON-RPC id (for MCP wrapping)
=/  cookies  *(map server-id:mcp-proxy @t)
=/  agg-pending  *(map @t agg-request)
=/  spec-cache  *(map server-id:mcp-proxy json)
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  =/  initial-key=@t  (gen-token eny.bowl)
  =.  client-key  `initial-key
  =/  sid=@tas  (self-id our.bowl)
  =/  self-url=@t  (build-self-url our.bowl now.bowl)
  =/  auth-header=header:mcp-proxy  ['x-api-key' initial-key]
  =/  self-srv=mcp-server:mcp-proxy
    :*  'Urbit MCP server'
        self-url
        ~[auth-header]
        %.y  ~  %proxy  ~
    ==
  =.  servers  (~(put by servers) sid self-srv)
  =.  server-order  [sid server-order]
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /apps/mcp/api] %mcp-proxy]
      [%pass /eyre/mcp %arvo %e %connect [~ /apps/mcp/mcp] %mcp-proxy]
      (sync-server-key-card our.bowl initial-key)
  ==
::
++  on-save  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  =/  old  (mule |.(!<(versioned-state:mcp-proxy old-state)))
  ?:  ?=(%| -.old)
    on-init
  =/  eyre-cards=(list card)
    :~  [%pass /eyre/connect %arvo %e %connect [~ /apps/mcp/api] %mcp-proxy]
        [%pass /eyre/mcp %arvo %e %connect [~ /apps/mcp/mcp] %mcp-proxy]
    ==
  =/  raw-state=state-4:mcp-proxy
    ?-  -.p.old
        %4  p.old
        %3  [%4 servers.p.old server-order.p.old tool-filters.p.old ~ ~]
        %2  [%4 servers.p.old server-order.p.old ~ ~ ~]
    ::
        %1
      =/  new-servers=(map server-id:mcp-proxy mcp-server:mcp-proxy)
        %-  ~(run by servers.p.old)
        |=(s=mcp-server-1:mcp-proxy [name.s url.s headers.s enabled.s oauth-provider.s %proxy ~])
      [%4 new-servers server-order.p.old ~ ~ ~]
    ::
        %0
      =/  new-servers=(map server-id:mcp-proxy mcp-server:mcp-proxy)
        %-  ~(run by servers.p.old)
        |=(s=mcp-server-0:mcp-proxy [name.s url.s headers.s enabled.s ~ %proxy ~])
      [%4 new-servers server-order.p.old ~ ~ ~]
    ==
  ::  ensure a client-key exists; generate if missing
  =/  ensured-key=@t
    ?~  client-key.raw-state  (gen-token eny.bowl)
    u.client-key.raw-state
  ::  rename any legacy %urbit-mcp upstream to the @p-derived id, and
  ::  ensure it exists with the right key + auto-derived loopback URL
  =/  sid=@tas  (self-id our.bowl)
  =/  legacy=(unit mcp-server:mcp-proxy)  (~(get by servers.raw-state) %urbit-mcp)
  =/  current=(unit mcp-server:mcp-proxy)  (~(get by servers.raw-state) sid)
  =/  prev=(unit mcp-server:mcp-proxy)  ?~(current legacy current)
  =/  url=@t
    ?~  prev  (build-self-url our.bowl now.bowl)
    ::  if previously stored URL was the old hardcoded port, refresh it
    ?:  =('http://localhost:8080/mcp' url.u.prev)
      (build-self-url our.bowl now.bowl)
    url.u.prev
  =/  auth-header=header:mcp-proxy  ['x-api-key' ensured-key]
  =/  self-srv=mcp-server:mcp-proxy
    :*  'Urbit MCP server'
        url
        ~[auth-header]
        %.y  ~  %proxy  ~
    ==
  =/  servers-no-legacy=(map server-id:mcp-proxy mcp-server:mcp-proxy)
    (~(del by servers.raw-state) %urbit-mcp)
  =/  patched-servers=(map server-id:mcp-proxy mcp-server:mcp-proxy)
    (~(put by servers-no-legacy) sid self-srv)
  =/  order-no-legacy=(list server-id:mcp-proxy)
    (skip server-order.raw-state |=(s=server-id:mcp-proxy =(s %urbit-mcp)))
  =/  patched-order=(list server-id:mcp-proxy)
    ?:  (~(has in (sy order-no-legacy)) sid)
      order-no-legacy
    [sid order-no-legacy]
  =/  new-state=state-4:mcp-proxy
    raw-state(client-key `ensured-key, servers patched-servers, server-order patched-order)
  ::  re-fetch specs for openapi servers (cache is non-persisted)
  =/  spec-cards=(list card)
    %+  murn  ~(tap by servers.new-state)
    |=  [sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy]
    ?.  =(%openapi mode.srv)  ~
    ?~  schema-url.srv  ~
    %-  some
    :*  %pass  /iris/spec/[sid]
        %arvo  %i  %request
        [%'GET' u.schema-url.srv ~[['accept' 'application/json']] ~]
        *outbound-config:iris
    ==
  ::  clear eyre cache for web UI files on every bump
  =/  cache-cards=(list card)
    %+  turn
      :~  '/apps/mcp'
          '/apps/mcp/'
          '/apps/mcp/index.html'
          '/apps/mcp/css/app.css'
          '/apps/mcp/js/app.js'
          '/apps/mcp/js/api.js'
      ==
    |=(url=@t [%pass /eyre/cache %arvo %e %set-response url ~])
  ::  re-sync key with mcp-server every load (idempotent)
  =/  sync-cards=(list card)  ~[(sync-server-key-card our.bowl ensured-key)]
  :_  this(state new-state)
  :(weld eyre-cards spec-cards cache-cards sync-cards)
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^
  ?+  mark  (on-poke:def mark vase)
      %mcp-proxy-action
    (handle-action !<(action:mcp-proxy vase))
  ::
      %json
    =/  jon=json  !<(json vase)
    =/  act=(unit action:mcp-proxy)  (parse-json-action jon)
    ?~  act  `this
    (handle-action u.act)
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    (handle-http eyre-id req)
  ::
      %noun
    ::  clear eyre cache for web UI files
    =/  urls=(list @t)
      :~  '/apps/mcp/'
          '/apps/mcp/index.html'
          '/apps/mcp/css/app.css'
          '/apps/mcp/js/app.js'
          '/apps/mcp/js/api.js'
      ==
    ~&  [%mcp-proxy %clearing-eyre-cache (lent urls)]
    :_  this
    %+  turn  urls
    |=(url=@t [%pass /eyre/cache %arvo %e %set-response url ~])
  ==
  ::
  ++  handle-action
    |=  act=action:mcp-proxy
    ^-  (quip card _this)
    ?>  =(src.bowl our.bowl)
    ?-  -.act
        %add-server
      ?:  (~(has by servers) id.act)  `this
      =.  servers  (~(put by servers) id.act mcp-server.act)
      =.  server-order  (snoc server-order id.act)
      ?:  ?&(=(%openapi mode.mcp-server.act) ?=(^ schema-url.mcp-server.act))
        (fetch-spec id.act u.schema-url.mcp-server.act)
      `this
        %remove-server
      =.  servers  (~(del by servers) id.act)
      =.  server-order  (skip server-order |=(s=server-id:mcp-proxy =(s id.act)))
      =.  cookies  (~(del by cookies) id.act)
      `this
        %update-server
      =.  servers  (~(put by servers) id.act mcp-server.act)
      `this
        %toggle-server
      =/  srv=(unit mcp-server:mcp-proxy)  (~(get by servers) id.act)
      ?~  srv  `this
      =.  servers  (~(put by servers) id.act u.srv(enabled !enabled.u.srv))
      `this
        %refresh-spec
      =/  srv=(unit mcp-server:mcp-proxy)  (~(get by servers) id.act)
      ?~  srv  `this
      ?.  =(%openapi mode.u.srv)  `this
      ?~  schema-url.u.srv  `this
      (fetch-spec id.act u.schema-url.u.srv)
    ::
        %set-tool-filter
      =.  tool-filters  (~(put by tool-filters) id.act tool-filter.act)
      `this
    ::
        %clear-tool-filter
      =.  tool-filters  (~(del by tool-filters) id.act)
      `this
    ::
        %login-server
      =/  srv=(unit mcp-server:mcp-proxy)  (~(get by servers) id.act)
      ?~  srv
        ~&  [%mcp-proxy %server-not-found id.act]
        `this
      ~&  [%mcp-proxy %found-server name.u.srv url.u.srv]
      (do-login id.act u.srv)
    ::
        %set-client-key
      =^  cards  state  (apply-key key.act)
      [cards this]
    ::
        %regenerate-client-key
      =^  cards  state  (apply-key (gen-token eny.bowl))
      [cards this]
    ::
        %clear-client-key
      =.  client-key  ~
      :_  this
      ~[(sync-server-key-card our.bowl '')]
    ::
        %set-internal-token
      ::  legacy: a no-op now that mcp-proxy owns the key
      `this
    ==
  ::
  ++  apply-key
    |=  new-key=@t
    ^-  (quip card state-4:mcp-proxy)
    =.  client-key  `new-key
    ::  ensure self upstream exists with the new key as its x-api-key header
    =/  sid=@tas  (self-id our.bowl)
    =/  prev=(unit mcp-server:mcp-proxy)  (~(get by servers) sid)
    =/  url=@t
      ?~  prev  (build-self-url our.bowl now.bowl)
      url.u.prev
    =/  auth-header=header:mcp-proxy  ['x-api-key' new-key]
    =/  self-srv=mcp-server:mcp-proxy
      :*  'Urbit MCP server'
          url
          ~[auth-header]
          %.y  ~  %proxy  ~
      ==
    =.  servers  (~(put by servers) sid self-srv)
    =?  server-order  !(~(has in (sy server-order)) sid)
      [sid server-order]
    :_  state
    ~[(sync-server-key-card our.bowl new-key)]
  ::
  ++  do-login
    |=  [sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy]
    ^-  (quip card _this)
    =/  code=@p
      .^(@p %j /(scot %p our.bowl)/code/(scot %da now.bowl)/(scot %p our.bowl))
    =/  pass=@t  (scot %p code)
    =/  base=@t  (get-base-url url.srv)
    =/  login-url=@t  (cat 3 base '/~/login')
    =/  body=@t  (cat 3 'password=' pass)
    ~&  [%mcp-proxy %logging-in login-url]
    :_  this
    :~  :*  %pass  /iris/login/[sid]
            %arvo  %i  %request
            [%'POST' login-url ~[['content-type' 'application/x-www-form-urlencoded']] `(as-octs:mimes:html body)]
            *outbound-config:iris
        ==
    ==
  ::
  ++  fetch-spec
    |=  [sid=server-id:mcp-proxy url=@t]
    ^-  (quip card _this)
    ~&  [%mcp-proxy %fetching-spec sid url]
    :_  this
    :~  :*  %pass  /iris/spec/[sid]
            %arvo  %i  %request
            [%'GET' url ~[['accept' 'application/json']] ~]
            *outbound-config:iris
        ==
    ==
  ::
  ++  handle-http
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  rl=request-line:server  (parse-request-line:server url.request.req)
    =/  site=(list @t)  site.rl
    ?:  ?=([%apps %mcp %mcp *] site)
      =/  rest=(list @t)  t.t.t.site
      ::  aggregate endpoint: /apps/mcp/mcp or /apps/mcp/mcp/
      ::
      ?:  |(=(~ rest) ?=([%$ ~] rest))
        (handle-agg eyre-id req)
      ::  single-server proxy: /apps/mcp/mcp/{server-id}
      ::
      (handle-mcp eyre-id req rest)
    ?.  ?=([%apps %mcp %api *] site)
      :_  this
      (give-http eyre-id 404 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'not found')))
    =/  api-path=(list @t)  t.t.t.site
    ?.  authenticated.req
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (login-redirect:gen:server request.req)
    ?:  =(%'GET' method.request.req)
      (handle-get eyre-id api-path)
    ?:  =(%'POST' method.request.req)
      (handle-post eyre-id req)
    :_  this
    (give-http eyre-id 405 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'method not allowed')))
  ::
  ++  handle-get
    |=  [eyre-id=@ta site=(list @t)]
    ^-  (quip card _this)
    ?+  site
      :_  this
      (give-http eyre-id 404 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'not found')))
        [%servers ~]
      :_  this
      (give-json eyre-id (build-servers-json ~))
    ::
        [%client-key ~]
      :_  this
      %+  give-json  eyre-id
      %-  pairs:enjs:format
      :~  :-  'clientKey'
          ?~  client-key  ~
          s+u.client-key
          ['hasKey' b+?=(^ client-key)]
      ==
    ::
        [%tools @ ~]
      ::  list tools for a specific server
      =/  sid=server-id:mcp-proxy  `@tas`i.t.site
      =/  srv=(unit mcp-server:mcp-proxy)  (~(get by servers) sid)
      ?~  srv
        :_  this
        (give-json eyre-id (pairs:enjs:format ~[['tools' a+~]]))
      ?:  =(%openapi mode.u.srv)
        ::  openapi: generate from cached spec
        =/  spec=(unit json)  (~(get by spec-cache) sid)
        ?~  spec
          :_  this
          (give-json eyre-id (pairs:enjs:format ~[['tools' a+~]]))
        =/  tools=(list json)  (apply-tool-filter sid (spec-to-tools sid u.spec) tool-filters)
        :_  this
        (give-json eyre-id (pairs:enjs:format ~[['tools' a+tools]]))
      ::  proxy: fetch tools/list from upstream via iris
      =/  upstream-body=@t
        %-  en:json:html
        %-  pairs:enjs:format
        :~  ['jsonrpc' s+'2.0']  ['method' s+'tools/list']
            ['id' (numb:enjs:format 1)]  ['params' (pairs:enjs:format ~)]
        ==
      =/  out-headers=(list [key=@t value=@t])
        %+  weld
          ~[['content-type' 'application/json'] ['accept' 'application/json']]
        headers.u.srv
      =/  cookie=(unit @t)  (~(get by cookies) sid)
      =?  out-headers  ?=(^ cookie)
        (snoc out-headers ['cookie' u.cookie])
      =/  oauth-hdr=(unit [key=@t value=@t])
        (get-oauth-header oauth-provider.u.srv our.bowl now.bowl)
      =?  out-headers  ?=(^ oauth-hdr)
        (snoc out-headers u.oauth-hdr)
      =/  wire-id=@t  (scot %uv `@uv`eny.bowl)
      =.  pending  (~(put by pending) wire-id eyre-id)
      :_  this
      :~  [%pass /iris/toolsapi/[wire-id] %arvo %i %request [%'POST' url.u.srv out-headers `(as-octs:mimes:html upstream-body)] *outbound-config:iris]
      ==
    ==
  ::
  ++  handle-post
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  body=@t
      ?~  body.request.req  ''
      `@t`q.u.body.request.req
    =/  jon=(unit json)  (de:json:html body)
    ?~  jon
      :_  this
      (give-http eyre-id 400 ~[cors] (some (as-octs:mimes:html '{"error":"bad json"}')))
    =/  act=(unit action:mcp-proxy)  (parse-json-action u.jon)
    ?~  act
      :_  this
      (give-http eyre-id 400 ~[cors] (some (as-octs:mimes:html '{"error":"bad action"}')))
    =/  result  (handle-action u.act)
    :_  +.result
    %+  weld  -.result
    (give-http eyre-id 200 ~[cors] (some (as-octs:mimes:html '{"ok":true}')))
  ::
  ::  extract x-api-key header value (case-insensitive)
  ::
  ++  get-api-key-header
    |=  req=inbound-request:eyre
    ^-  (unit @t)
    =/  hdrs=(list [key=@t value=@t])  header-list.request.req
    |-  ^-  (unit @t)
    ?~  hdrs  ~
    ?:  =((cass (trip key.i.hdrs)) "x-api-key")  `value.i.hdrs
    $(hdrs t.hdrs)
  ::
  ::  verify x-api-key header matches stored client-key
  ::
  ++  check-client-key
    |=  req=inbound-request:eyre
    ^-  ?
    ?~  client-key  %.n
    =/  supplied=(unit @t)  (get-api-key-header req)
    ?~  supplied  %.n
    =(u.supplied u.client-key)
  ::
  ::  aggregate endpoint: combine tools from all servers
  ::
  ++  handle-agg
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    ::  CORS
    ?:  =(%'OPTIONS' method.request.req)
      :_  this
      %-  give-http  :^  eyre-id  204
      :~  cors
          ['access-control-allow-methods' 'GET, POST, DELETE, OPTIONS']
          ['access-control-allow-headers' 'Content-Type, Accept, Authorization, Mcp-Session-Id, X-Api-Key']
          ['access-control-expose-headers' 'Mcp-Session-Id']
          ['access-control-max-age' '86400']
      ==
      ~
    ::  require client-key to be set
    ?~  client-key
      :_  this
      %-  give-http  :^  eyre-id  503
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"proxy not configured: set an x-api-key via the GUI"}'))
    ::  verify x-api-key header
    ?.  (check-client-key req)
      :_  this
      %-  give-http  :^  eyre-id  401
      ~[cors ['content-type' 'application/json'] ['www-authenticate' 'X-Api-Key']]
      (some (as-octs:mimes:html '{"error":"missing or invalid x-api-key"}'))
    ::  non-POST: return 200 empty (GET SSE not supported)
    ?.  =(%'POST' method.request.req)
      :_  this
      (give-http eyre-id 200 ~[cors] ~)
    =/  body=@t
      ?~  body.request.req  ''
      `@t`q.u.body.request.req
    =/  jon=(unit json)  (de:json:html body)
    ?~  jon
      :_  this
      (give-http eyre-id 400 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"bad json"}')))
    =/  method=@t  (get-json-string u.jon 'method')
    =/  req-id=json  (get-json-field u.jon 'id')
    ::
    ?+  method
      :_  this
      (give-http eyre-id 400 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"unknown method"}')))
    ::
        %'initialize'
      :_  this
      =/  resp=json
        %-  pairs:enjs:format
        :~  ['jsonrpc' s+'2.0']
            ['id' req-id]
            :-  'result'
            %-  pairs:enjs:format
            :~  :-  'capabilities'
                %-  pairs:enjs:format
                :~  ['tools' (pairs:enjs:format ~[['listChanged' b+|]])]
                    ['resources' (pairs:enjs:format ~[['listChanged' b+|] ['subscribe' b+|]])]
                    ['prompts' (pairs:enjs:format ~[['listChanged' b+|]])]
                ==
                :-  'serverInfo'
                %-  pairs:enjs:format
                :~  ['name' s+(crip "{(trip (scot %p our.bowl))} mcp-proxy")]
                    ['version' s+'1.0.0']
                ==
                ['protocolVersion' s+'2024-11-05']
            ==
        ==
      (give-http eyre-id 200 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html (en:json:html resp))))
    ::
        %'notifications/initialized'
      :_  this
      (give-http eyre-id 200 ~[cors] ~)
    ::
        ?(%'tools/list' %'resources/list' %'prompts/list')
      (fan-out eyre-id req-id method)
    ::
        ?(%'tools/call' %'resources/read' %'prompts/get')
      ~&  [%mcp-proxy %routing-call method (get-json-string (get-json-field u.jon 'params') 'name')]
      (route-call eyre-id req u.jon method)
    ==
  ::
  ::  fan out a list request to all enabled servers
  ::
  ++  fan-out
    |=  [eyre-id=@ta req-id=json method=@t]
    ^-  (quip card _this)
    =/  result-key=@t
      ?+  method  'items'
        %'tools/list'      'tools'
        %'resources/list'  'resources'
        %'prompts/list'    'prompts'
      ==
    =/  enabled=(list [server-id:mcp-proxy mcp-server:mcp-proxy])
      %+  skim
        %+  turn  server-order
        |=(sid=server-id:mcp-proxy [sid (~(got by servers) sid)])
      |=([* srv=mcp-server:mcp-proxy] enabled.srv)
    ?~  enabled
      =/  resp=json
        %-  pairs:enjs:format
        :~  ['jsonrpc' s+'2.0']  ['id' req-id]
            ['result' (pairs:enjs:format ~[[result-key a+~]])]
        ==
      :_  this
      (give-http eyre-id 200 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html (en:json:html resp))))
    ::  separate proxy servers (need Iris) from openapi servers (local)
    =/  all=(list [server-id:mcp-proxy mcp-server:mcp-proxy])
      (turn enabled |=([sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy] [sid srv]))
    =/  proxy-servers=(list [server-id:mcp-proxy mcp-server:mcp-proxy])
      (skim all |=([sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy] =(%proxy mode.srv)))
    =/  openapi-servers=(list [server-id:mcp-proxy mcp-server:mcp-proxy])
      (skim all |=([sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy] =(%openapi mode.srv)))
    ::  generate openapi results locally from cached specs
    =/  local-results=(map server-id:mcp-proxy (unit json))
      %-  ~(gas by *(map server-id:mcp-proxy (unit json)))
      %+  turn  openapi-servers
      |=  [sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy]
      =/  spec=(unit json)  (~(get by spec-cache) sid)
      ?~  spec  [sid ~]
      ?.  =(%'tools/list' method)
        ::  openapi only supports tools for now
        [sid `(pairs:enjs:format ~[['jsonrpc' s+'2.0'] ['id' (numb:enjs:format 1)] ['result' (pairs:enjs:format ~[[result-key a+~]])]])]
      =/  tools=(list json)  (apply-tool-filter sid (spec-to-tools sid u.spec) tool-filters)
      [sid `(pairs:enjs:format ~[['jsonrpc' s+'2.0'] ['id' (numb:enjs:format 1)] ['result' (pairs:enjs:format ~[['tools' a+tools]])]])]
    =/  total=@ud  (lent enabled)
    ::  if no proxy servers, respond immediately with local results
    ?.  ?=(^ proxy-servers)
      =.  agg-pending
        (~(put by agg-pending) 'immediate' [eyre-id req-id method total local-results])
      ::  trigger immediate aggregation via the on-arvo path - but we have all results
      ::  just combine and respond directly
      =/  name-key=@t
        ?+  method  'name'
          %'tools/list'  'name'  %'resources/list'  'uri'  %'prompts/list'  'name'
        ==
      =/  all-items=(list json)
        %-  zing
        %+  turn  ~(tap by local-results)
        |=  [s-id=server-id:mcp-proxy res=(unit json)]
        ?~  res  ~
        =/  result=json  (get-json-field u.res 'result')
        ?.  ?=(%o -.result)  ~
        =/  items-json=(unit json)  (~(get by p.result) result-key)
        ?~  items-json  ~
        ?.  ?=(%a -.u.items-json)  ~
        %+  turn  p.u.items-json
        |=  item=json
        ?.  ?=(%o -.item)  item
        =/  orig-name=@t
          =/  n=(unit json)  (~(get by p.item) name-key)
          ?~  n  ''  ?.  ?=(%s -.u.n)  ''  p.u.n
        [%o (~(put by p.item) name-key s+(cat 3 (cat 3 (scot %tas s-id) '_') orig-name))]
      =/  resp=json
        %-  pairs:enjs:format
        :~  ['jsonrpc' s+'2.0']  ['id' req-id]
            ['result' (pairs:enjs:format ~[[result-key a+all-items]])]
        ==
      :_  this
      (give-http eyre-id 200 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html (en:json:html resp))))
    ::  has proxy servers: set up agg-pending with local results pre-populated
    =/  group-id=@t  (scot %uv `@uv`eny.bowl)
    =.  agg-pending
      (~(put by agg-pending) group-id [eyre-id req-id method total local-results])
    =/  upstream-body=@t
      %-  en:json:html
      %-  pairs:enjs:format
      :~  ['jsonrpc' s+'2.0']  ['method' s+method]
          ['id' (numb:enjs:format 1)]  ['params' (pairs:enjs:format ~)]
      ==
    :_  this
    %+  turn  proxy-servers
    |=  [sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy]
    =/  out-headers=(list [key=@t value=@t])
      %+  weld
        ~[['content-type' 'application/json'] ['accept' 'application/json']]
      headers.srv
    =/  cookie=(unit @t)  (~(get by cookies) sid)
    =?  out-headers  ?=(^ cookie)
      (snoc out-headers ['cookie' u.cookie])
    =/  oauth-hdr=(unit [key=@t value=@t])
      (get-oauth-header oauth-provider.srv our.bowl now.bowl)
    =?  out-headers  ?=(^ oauth-hdr)
      (snoc out-headers u.oauth-hdr)
    :*  %pass  /iris/agg/[group-id]/[sid]
        %arvo  %i  %request
        [%'POST' url.srv out-headers `(as-octs:mimes:html upstream-body)]
        *outbound-config:iris
    ==
  ::
  ::  route a call/read/get to a specific server based on name prefix
  ::
  ++  route-call
    |=  [eyre-id=@ta req=inbound-request:eyre jon=json method=@t]
    ^-  (quip card _this)
    =/  params=json  (get-json-field jon 'params')
    =/  req-id=json  (get-json-field jon 'id')
    =/  name-key=@t
      ?+  method  'name'
        %'tools/call'  'name'  %'resources/read'  'uri'  %'prompts/get'  'name'
      ==
    =/  full-name=@t  (get-json-string params name-key)
    =/  [sid=@t real-name=@t]  (split-on-underscore full-name)
    =/  srv=(unit mcp-server:mcp-proxy)  (~(get by servers) `@tas`sid)
    ?~  srv
      :_  this
      %-  give-http  :^  eyre-id  404
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"server not found in tool prefix"}'))
    ::  build auth headers
    =/  out-headers=(list [key=@t value=@t])
      %+  weld
        ~[['accept' 'application/json']]
      headers.u.srv
    =/  cookie=(unit @t)  (~(get by cookies) `@tas`sid)
    =?  out-headers  ?=(^ cookie)
      (snoc out-headers ['cookie' u.cookie])
    =/  oauth-hdr=(unit [key=@t value=@t])
      (get-oauth-header oauth-provider.u.srv our.bowl now.bowl)
    =?  out-headers  ?=(^ oauth-hdr)
      (snoc out-headers u.oauth-hdr)
    ::  openapi mode: make direct REST API call
    ?:  =(%openapi mode.u.srv)
      ~&  [%mcp-proxy %openapi-call sid real-name]
      =/  spec=(unit json)  (~(get by spec-cache) `@tas`sid)
      ?~  spec
        ~&  [%mcp-proxy %spec-not-cached sid]
        :_  this
        %-  give-http  :^  eyre-id  500
        ~[cors ['content-type' 'application/json']]
        (some (as-octs:mimes:html '{"error":"spec not cached, try again"}'))
      =/  op=(unit [path=@t method=@t operation=json])
        (find-operation u.spec real-name)
      ?~  op
        ~&  [%mcp-proxy %op-not-found sid real-name]
        :_  this
        %-  give-http  :^  eyre-id  404
        ~[cors ['content-type' 'application/json']]
        (some (as-octs:mimes:html '{"error":"operation not found in spec"}'))
      ~&  [%mcp-proxy %found-op path.u.op method.u.op]
      ::  extract arguments from params
      =/  args=json
        =/  a=(unit json)  ?.(?=(%o -.params) ~ (~(get by p.params) 'arguments'))
        (fall a params)
      ::  build API URL with path params and query string
      =/  path-params=(set @t)  (extract-path-params path.u.op)
      =/  api-url=@t
        ::  use server URL if set, otherwise derive from spec
        =/  base-url=@t
          ?:  !=('' url.u.srv)  url.u.srv
          (get-spec-base-url u.spec)
        ~&  [%mcp-proxy %base-url base-url]
        =/  base-with-path=@t  (build-api-url base-url path.u.op args)
        ~&  [%mcp-proxy %base-with-path base-with-path]
        =/  qs=@t  (build-all-args-query args path-params)
        ~&  [%mcp-proxy %query-string qs]
        (cat 3 base-with-path qs)
      ~&  [%mcp-proxy %api-url api-url]
      ::  build body for POST/PUT/PATCH
      =/  req-method=method:http
        ?+  method.u.op  %'GET'
          %'get'  %'GET'  %'post'  %'POST'  %'put'  %'PUT'
          %'patch'  %'PATCH'  %'delete'  %'DELETE'
        ==
      =/  has-body=?
        ?|  =(req-method %'POST')
            =(req-method %'PUT')
            =(req-method %'PATCH')
        ==
      =/  body=(unit octs)
        ?.  has-body  ~
        `(as-octs:mimes:html (en:json:html args))
      =?  out-headers  has-body
        [['content-type' 'application/json'] out-headers]
      ::  store eyre-id and use behn to respond from on-arvo
      =/  wire-id=@t  (scot %uv `@uv`eny.bowl)
      =/  client-rpc-id=json  (get-json-field jon 'id')
      =.  pending  (~(put by pending) wire-id eyre-id)
      =.  wrap-set  (~(put by wrap-set) wire-id client-rpc-id)
      =/  =request:http  [req-method api-url out-headers body]
      :_  this
      :~  [%pass /iris/proxy/[wire-id] %arvo %i %request request *outbound-config:iris]
      ==
    ::  proxy mode: forward as MCP request
    =/  new-params=json
      ?>  ?=(%o -.params)
      [%o (~(put by p.params) name-key s+real-name)]
    =/  new-body=@t
      %-  en:json:html
      ?>  ?=(%o -.jon)
      [%o (~(put by p.jon) 'params' new-params)]
    =.  out-headers  [['content-type' 'application/json'] out-headers]
    =/  wire-id=@t  (scot %uv `@uv`eny.bowl)
    =.  pending  (~(put by pending) wire-id eyre-id)
    :_  this
    :~  :*  %pass  /iris/proxy/[wire-id]
            %arvo  %i  %request
            [%'POST' url.u.srv out-headers `(as-octs:mimes:html new-body)]
            *outbound-config:iris
        ==
    ==
  ::
  ::  single-server direct proxy (existing behavior)
  ::
  ++  handle-mcp
    |=  [eyre-id=@ta req=inbound-request:eyre site=(list @t)]
    ^-  (quip card _this)
    ?:  =(%'OPTIONS' method.request.req)
      :_  this
      %-  give-http  :^  eyre-id  204
      :~  cors
          ['access-control-allow-methods' 'GET, POST, DELETE, OPTIONS']
          ['access-control-allow-headers' 'Content-Type, Accept, Authorization, Mcp-Session-Id, X-Api-Key']
          ['access-control-expose-headers' 'Mcp-Session-Id']
          ['access-control-max-age' '86400']
      ==
      ~
    ::  require client-key
    ?~  client-key
      :_  this
      %-  give-http  :^  eyre-id  503
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"proxy not configured: set an x-api-key via the GUI"}'))
    ?.  (check-client-key req)
      :_  this
      %-  give-http  :^  eyre-id  401
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"missing or invalid x-api-key"}'))
    ?~  site
      :_  this
      %-  give-http  :^  eyre-id  400
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"missing server id"}'))
    =/  sid=server-id:mcp-proxy  i.site
    =/  srv=(unit mcp-server:mcp-proxy)  (~(get by servers) sid)
    ?~  srv
      :_  this
      %-  give-http  :^  eyre-id  404
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"server not found"}'))
    ?.  enabled.u.srv
      :_  this
      %-  give-http  :^  eyre-id  503
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"server disabled"}'))
    =/  out-headers=(list [key=@t value=@t])
      %+  weld
        ~[['content-type' 'application/json'] ['accept' 'application/json, text/event-stream']]
      headers.u.srv
    =/  cookie=(unit @t)  (~(get by cookies) sid)
    =?  out-headers  ?=(^ cookie)
      (snoc out-headers ['cookie' u.cookie])
    =/  oauth-hdr=(unit [key=@t value=@t])
      (get-oauth-header oauth-provider.u.srv our.bowl now.bowl)
    =?  out-headers  ?=(^ oauth-hdr)
      (snoc out-headers u.oauth-hdr)
    =/  session-id=(unit @t)
      =/  hdrs=(list [key=@t value=@t])  header-list.request.req
      |-
      ?~  hdrs  ~
      ?:  =(key.i.hdrs 'mcp-session-id')  `value.i.hdrs
      $(hdrs t.hdrs)
    =?  out-headers  ?=(^ session-id)
      (snoc out-headers ['mcp-session-id' u.session-id])
    =/  wire-id=@t  (scot %uv `@uv`eny.bowl)
    =.  pending  (~(put by pending) wire-id eyre-id)
    :_  this
    :~  :*  %pass  /iris/proxy/[wire-id]
            %arvo  %i  %request
            [method.request.req url.u.srv out-headers body.request.req]
            *outbound-config:iris
        ==
    ==
  ::
  ++  build-servers-json
    |=  ~
    ^-  json
    =,  enjs:format
    %-  pairs
    :~  ['ship' s+(scot %p our.bowl)]
        :-  'servers'
        :-  %a
        %+  turn  server-order
        |=  sid=server-id:mcp-proxy
        =/  srv=mcp-server:mcp-proxy  (~(got by servers) sid)
        =/  has-cookie=?  (~(has by cookies) sid)
        %-  pairs
        :~  ['id' s+(scot %tas sid)]
            ['name' s+name.srv]
            ['url' s+url.srv]
            ['enabled' b+enabled.srv]
            ['authenticated' b+has-cookie]
            ['mode' s+?:(?=(%proxy mode.srv) 'proxy' 'openapi')]
            :-  'schemaUrl'
            ?~  schema-url.srv  ~
            s+u.schema-url.srv
            :-  'oauthProvider'
            ?~  oauth-provider.srv  ~
            s+(scot %tas u.oauth-provider.srv)
            ['hasCachedSpec' b+(~(has by spec-cache) sid)]
            :-  'toolFilter'
            =/  filt=(unit tool-filter:mcp-proxy)  (~(get by tool-filters) sid)
            ?~  filt  ~
            %-  pairs:enjs:format
            :~  ['mode' s+?:(?=(%allow mode.u.filt) 'allow' 'block')]
                ['tools' a+(turn ~(tap in tools.u.filt) |=(t=@t s+t))]
            ==
            :-  'headers'
            :-  %a
            %+  turn  headers.srv
            |=  h=header:mcp-proxy
            (pairs ~[['key' s+key.h] ['value' s+value.h]])
        ==
    ==
  --
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
      [%http-response @ ~]
    `this
  ==
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  `this
      [%eyre *]
    ?:  ?=(%bound +<.sign)
      ~?  !accepted.sign  [%mcp-proxy %binding-rejected binding.sign]
      `this
    `this
  ::
      [%iris %spec @ ~]
    ::  OpenAPI spec fetch response
    ::
    =/  sid=server-id:mcp-proxy  i.t.t.wire
    ?.  ?=([%iris %http-response *] sign)
      ~&  [%mcp-proxy %spec-fetch-failed sid %bad-sign]
      `this
    =/  resp=client-response:iris  client-response.sign
    ?.  ?=(%finished -.resp)
      ~&  [%mcp-proxy %spec-fetch-failed sid %not-finished]
      `this
    ?.  =(200 status-code.response-header.resp)
      ~&  [%mcp-proxy %spec-fetch-failed sid %status status-code.response-header.resp]
      `this
    ?~  full-file.resp
      ~&  [%mcp-proxy %spec-fetch-failed sid %no-body]
      `this
    =/  body=@t  `@t`q.data.u.full-file.resp
    =/  jon=(unit json)  (de:json:html body)
    ?~  jon
      ~&  [%mcp-proxy %spec-fetch-failed sid %bad-json]
      `this
    ~&  [%mcp-proxy %spec-cached sid]
    `this(spec-cache (~(put by spec-cache) sid u.jon))
  ::
      [%iris %toolsapi @ ~]
    ::  tools API response: parse MCP response and extract tools list
    =/  wire-id=@t  i.t.t.wire
    =/  eid=(unit @ta)  (~(get by pending) wire-id)
    ?~  eid  `this
    =.  pending  (~(del by pending) wire-id)
    ?.  ?=([%iris %http-response *] sign)
      :_  this
      (give-http u.eid 502 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html '{"tools":[]}')))
    =/  resp=client-response:iris  client-response.sign
    ?.  ?=(%finished -.resp)
      :_  this
      (give-http u.eid 200 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html '{"tools":[]}')))
    =/  body=@t
      ?~  full-file.resp  ''
      `@t`q.data.u.full-file.resp
    ::  strip SSE prefix if present
    =/  clean=@t  (strip-sse body)
    =/  jon=(unit json)  (de:json:html clean)
    =/  tools=(list json)
      ?~  jon  ~
      ::  MCP response: {"result":{"tools":[...]}}
      =/  result=json  (get-json-field u.jon 'result')
      =/  tl=json  (get-json-field result 'tools')
      ?.  ?=(%a -.tl)  ~
      p.tl
    =/  resp-body=@t  (en:json:html (pairs:enjs:format ~[['tools' a+tools]]))
    :_  this
    (give-http u.eid 200 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html resp-body)))
  ::
      [%iris %login @ ~]
    =/  sid=server-id:mcp-proxy  i.t.t.wire
    ?.  ?=([%iris %http-response *] sign)
      ~&  [%mcp-proxy %login-failed sid %bad-sign]
      `this
    =/  resp=client-response:iris  client-response.sign
    ?.  ?=(%finished -.resp)
      ~&  [%mcp-proxy %login-failed sid %not-finished]
      `this
    ?.  =(200 status-code.response-header.resp)
      ~&  [%mcp-proxy %login-failed sid %status status-code.response-header.resp]
      `this
    =/  cookie=(unit @t)
      =/  hdrs=(list [key=@t value=@t])  headers.response-header.resp
      |-
      ?~  hdrs  ~
      ?:  =(key.i.hdrs 'set-cookie')
        =/  val=tape  (trip value.i.hdrs)
        =/  semi=(unit @ud)  (find ";" val)
        ?~  semi  `value.i.hdrs
        `(crip (scag u.semi val))
      $(hdrs t.hdrs)
    ?~  cookie
      ~&  [%mcp-proxy %login-failed sid %no-cookie]
      `this
    ~&  [%mcp-proxy %login-ok sid]
    `this(cookies (~(put by cookies) sid u.cookie))
  ::
  ::
      [%iris %proxy @ ~]
    =/  wire-id=@t  i.t.t.wire
    =/  eid=(unit @ta)  (~(get by pending) wire-id)
    ?~  eid
      ~&  [%mcp-proxy %no-pending wire-id]
      `this
    =.  pending  (~(del by pending) wire-id)
    =/  client-id=(unit json)  (~(get by wrap-set) wire-id)
    =/  needs-wrap=?  ?=(^ client-id)
    =?  wrap-set  needs-wrap  (~(del by wrap-set) wire-id)
    ?.  ?=([%iris %http-response *] sign)
      :_  this
      %-  give-http  :^  u.eid  502
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"unexpected iris response"}'))
    =/  resp=client-response:iris  client-response.sign
    ?.  ?=(%finished -.resp)
      :_  this
      %-  give-http  :^  u.eid  502
      ~[cors ['content-type' 'application/json']]
      (some (as-octs:mimes:html '{"error":"upstream in progress"}'))
    ::  for openapi calls, wrap the REST response in MCP format
    ?:  needs-wrap
      =/  body-text=@t
        ?~  full-file.resp  ''
        `@t`q.data.u.full-file.resp
      =/  is-error=?  (gte status-code.response-header.resp 400)
      ::  on 401, trigger a token refresh for next call
      ::  on 401, trigger force-refresh for the oauth provider (fire-and-forget)
      ::  next call will use the refreshed token
      =/  refresh-cards=(list card)
        ?.  =(401 status-code.response-header.resp)  ~
        ::  find which server had this wire and get its oauth provider
        =/  srv-list=(list [server-id:mcp-proxy mcp-server:mcp-proxy])
          %+  skim  ~(tap by servers)
          |=([* s=mcp-server:mcp-proxy] ?=(^ oauth-provider.s))
        %+  murn  srv-list
        |=  [sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy]
        ?~  oauth-provider.srv  ~
        %-  some
        [%pass /oauth-refresh/[u.oauth-provider.srv] %agent [our.bowl %oauth] %poke %oauth-action !>(`action:oauth`[%force-refresh u.oauth-provider.srv])]
      =/  mcp-resp=@t
        %-  en:json:html
        %-  pairs:enjs:format
        :~  ['jsonrpc' s+'2.0']
            ['id' (fall client-id (numb:enjs:format 1))]
            :-  'result'
            %-  pairs:enjs:format
            :~  :-  'content'
                :-  %a
                :~  (pairs:enjs:format ~[['type' s+'text'] ['text' s+body-text]])
                ==
                ['isError' b+is-error]
            ==
        ==
      =/  resp-headers=(list [key=@t value=@t])
        ~[cors ['content-type' 'application/json'] ['cache-control' 'no-cache'] ['access-control-expose-headers' 'Mcp-Session-Id'] ['content-encoding' 'identity']]
      =/  bod=(unit octs)  `(as-octs:mimes:html mcp-resp)
      :_  this
      =/  =path  /http-response/[u.eid]
      =/  http-cards=(list card)
        :~  [%give %fact ~[path] %http-response-header !>(`response-header:http`[200 resp-headers])]
            [%give %fact ~[path] %http-response-data !>(bod)]
            [%give %kick ~[path] ~]
        ==
      (weld http-cards refresh-cards)
    ::  for proxy calls, forward upstream response as-is
    =/  resp-headers=(list [key=@t value=@t])
      %+  weld  ~[cors ['access-control-expose-headers' 'Mcp-Session-Id']]
      %+  skip  headers.response-header.resp
      |=  [key=@t value=@t]
      ?|(=(key 'transfer-encoding') =(key 'connection'))
    =/  bod=(unit octs)
      ?~  full-file.resp  ~
      `data.u.full-file.resp
    :_  this
    =/  =path  /http-response/[u.eid]
    :~  [%give %fact ~[path] %http-response-header !>(`response-header:http`[status-code.response-header.resp resp-headers])]
        [%give %fact ~[path] %http-response-data !>(bod)]
        [%give %kick ~[path] ~]
    ==
  ::
      [%iris %agg @ @ ~]
    ::  aggregate response: /iris/agg/{group-id}/{server-id}
    ::
    =/  group-id=@t  i.t.t.wire
    =/  sid=server-id:mcp-proxy  i.t.t.t.wire
    =/  req=(unit agg-request)  (~(get by agg-pending) group-id)
    ?~  req
      ~&  [%mcp-proxy %agg-no-pending group-id sid]
      `this
    ::  parse the upstream response (handles both plain JSON and SSE format)
    =/  result-json=(unit json)
      ?.  ?=([%iris %http-response *] sign)  ~
      =/  resp=client-response:iris  client-response.sign
      ?.  ?=(%finished -.resp)  ~
      ?.  =(200 status-code.response-header.resp)  ~
      ?~  full-file.resp  ~
      =/  body=@t  `@t`q.data.u.full-file.resp
      ::  strip SSE "data: " prefix if present
      =/  clean=@t  (strip-sse body)
      (de:json:html clean)
    ::  store result (~ if failed, which is ok)
    =/  new-results=(map server-id:mcp-proxy (unit json))
      (~(put by results.u.req) sid result-json)
    =/  received=@ud  ~(wyt by new-results)
    ::  not all in yet: update and wait
    ?.  =(received total.u.req)
      =.  agg-pending
        (~(put by agg-pending) group-id u.req(results new-results))
      `this
    ::  all responses in: combine and respond
    =.  agg-pending  (~(del by agg-pending) group-id)
    =/  result-key=@t
      ?+  method.u.req  'items'
        %'tools/list'      'tools'
        %'resources/list'  'resources'
        %'prompts/list'    'prompts'
      ==
    =/  name-key=@t
      ?+  method.u.req  'name'
        %'tools/list'      'name'
        %'resources/list'  'uri'
        %'prompts/list'    'name'
      ==
    ::  combine items from all servers, prefixing names
    =/  all-items=(list json)
      %-  zing
      %+  turn  ~(tap by new-results)
      |=  [s-id=server-id:mcp-proxy res=(unit json)]
      ?~  res  ~
      =/  result=json  (get-json-field u.res 'result')
      ?.  ?=(%o -.result)  ~
      =/  items-json=(unit json)  (~(get by p.result) result-key)
      ?~  items-json  ~
      ?.  ?=(%a -.u.items-json)  ~
      ::  prefix each item's name with server-id_
      %+  turn  p.u.items-json
      |=  item=json
      ?.  ?=(%o -.item)  item
      =/  orig-name=@t
        =/  n=(unit json)  (~(get by p.item) name-key)
        ?~  n  ''
        ?.  ?=(%s -.u.n)  ''
        p.u.n
      =/  prefixed=@t  (cat 3 (cat 3 (scot %tas s-id) '_') orig-name)
      [%o (~(put by p.item) name-key s+prefixed)]
    ::  build combined response
    =/  resp=json
      %-  pairs:enjs:format
      :~  ['jsonrpc' s+'2.0']
          ['id' req-id.u.req]
          ['result' (pairs:enjs:format ~[[result-key a+all-items]])]
      ==
    :_  this
    (give-http eyre-id.u.req 200 ~[cors ['content-type' 'application/json']] (some (as-octs:mimes:html (en:json:html resp))))
  ==
::
++  on-leave  on-leave:def
++  on-agent  on-agent:def
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  ~
      [%x %dbug %state ~]  ``noun+!>(state)
  ==
::
++  on-fail  on-fail:def
--
::
::  helper core
::
|%
++  cors  ['access-control-allow-origin' '*']
::
::  generate a random token from entropy (base32 encoded sha)
::
++  gen-token
  |=  eny=@
  ^-  @t
  =/  hash=@  (shaz eny)
  ::  drop the ~0v prefix from (scot %uv ...)
  =/  raw=tape  (trip (scot %uv hash))
  (crip (slag 3 raw))
::
::  poke mcp-server with the shared API key so /mcp validates against same value
::  caller passes our.bowl since we're in the helper core
::
++  sync-server-key-card
  |=  [our=@p key=@t]
  ^-  card:agent:gall
  :*  %pass  /sync/auth-token
      %agent  [our %mcp-server]
      %poke   %set-auth-token
      !>(key)
  ==
::
::  derive the self-loopback URL by scrying eyre for the bound port
::
++  build-self-url
  |=  [our=@p now=@da]
  ^-  @t
  =/  res=(unit [insecure=@ud secure=(unit @ud)])
    =/  m  (mule |.(.^([insecure=@ud secure=(unit @ud)] %e /(scot %p our)/ports/(scot %da now))))
    ?:(?=(%& -.m) `p.m ~)
  ?~  res  'http://localhost/mcp'
  =/  port=@ud  insecure.u.res
  (rap 3 ~['http://localhost:' (crip (a-co:co port)) '/mcp'])
::
::  derive the self upstream id from the ship name (no leading tilde)
::
++  self-id
  |=  our=@p
  ^-  @tas
  `@tas`(crip (slag 1 (trip (scot %p our))))
::
++  http-methods  (silt ~['get' 'post' 'put' 'patch' 'delete'])
::
::  convert an OpenAPI spec to a list of MCP tool JSON objects
::
++  spec-to-tools
  |=  [sid=server-id:mcp-proxy spec=json]
  ^-  (list json)
  ::  detect format: Google Discovery vs OpenAPI
  =/  kind=@t  (get-json-string spec 'kind')
  ?:  =(kind 'discovery#restDescription')
    (discovery-to-tools spec)
  (openapi-to-tools spec)
::
::  convert Google Discovery Document to MCP tools
::
++  discovery-to-tools
  |=  spec=json
  ^-  (list json)
  =/  resources=json  (get-json-field spec 'resources')
  ?.  ?=(%o -.resources)  ~
  =/  res  (mule |.((walk-discovery-resources resources)))
  ?:(?=(%& -.res) p.res ~)
::
++  walk-discovery-resources
  |=  resources=json
  ^-  (list json)
  ?~  resources  ~
  ?.  ?=(%o -.resources)  ~
  %-  zing
  %+  turn  ~(tap by p.resources)
  |=  [rname=@t robj=json]
  ?~  robj  ~
  ?.  ?=(%o -.robj)  ~
  =/  methods=json  (get-json-field robj 'methods')
  =/  method-tools=(list json)
    ?~  methods  ~
    ?.  ?=(%o -.methods)  ~
    %+  murn  ~(tap by p.methods)
    |=  [mname=@t mobj=json]
    ^-  (unit json)
    ?~  mobj  ~
    ?.  ?=(%o -.mobj)  ~
    =/  op-id=@t  (get-json-string mobj 'id')
    ?:  =('' op-id)  ~
    =/  desc=@t  (get-json-string mobj 'description')
    =/  params-obj=json  (get-json-field mobj 'parameters')
    =/  props=(map @t json)  ~
    =/  reqs=(list json)  ~
    =?  props  &(?=(^ params-obj) ?=(%o -.params-obj))
      %-  ~(gas by props)
      %+  murn  ~(tap by p.params-obj)
      |=  [pname=@t pobj=json]
      ^-  (unit [@t json])
      ?~  pobj  ~
      ?.  ?=(%o -.pobj)  ~
      =/  ptype=@t  (get-json-string pobj 'type')
      =/  pdesc=@t  (get-json-string pobj 'description')
      =/  prop=(map @t json)
        (~(put by *(map @t json)) 'type' s+?:(=('' ptype) 'string' ptype))
      =?  prop  !=('' pdesc)
        (~(put by prop) 'description' s+pdesc)
      `[pname [%o prop]]
    =?  reqs  &(?=(^ params-obj) ?=(%o -.params-obj))
      %+  murn  ~(tap by p.params-obj)
      |=  [pname=@t pobj=json]
      ?~  pobj  ~
      ?.  ?=(%o -.pobj)  ~
      ?.  =([~ %b %.y] (~(get by p.pobj) 'required'))  ~
      `s+pname
    =/  has-req=?  (~(has by p.mobj) 'request')
    =?  props  has-req
      (~(put by props) 'body' [%o (~(put by *(map @t json)) 'type' s+'string')])
    %-  some
    %-  pairs:enjs:format
    :~  ['name' s+op-id]
        ['description' s+desc]
        :-  'inputSchema'
        %-  pairs:enjs:format
        :~  ['type' s+'object']
            ['properties' [%o props]]
            ['required' [%a reqs]]
        ==
    ==
  =/  sub-resources=json  (get-json-field robj 'resources')
  =/  sub-tools=(list json)
    ?~  sub-resources  ~
    ?.  ?=(%o -.sub-resources)  ~
    (walk-discovery-resources sub-resources)
  (weld method-tools sub-tools)
::
::  convert OpenAPI spec to MCP tools
::
++  openapi-to-tools
  |=  spec=json
  ^-  (list json)
  =/  paths=json  (get-json-field spec 'paths')
  ?.  ?=(%o -.paths)  ~
  =/  result=(list json)  ~
  =/  items=(list [@t json])  ~(tap by p.paths)
  |-
  ?~  items  (flop result)
  =/  [path-str=@t path-item=json]  i.items
  ?.  ?=(%o -.path-item)  $(items t.items)
  =/  meths=(list [@t json])  ~(tap by p.path-item)
  =/  path-tools=(list json)
    =/  ml=(list [@t json])  meths
    |-
    ?~  ml  ~
    =/  [meth=@t op=json]  i.ml
    ?.  (~(has in http-methods) meth)  $(ml t.ml)
    ?.  ?=(%o -.op)  $(ml t.ml)
    =/  op-id=@t  (get-json-string op 'operationId')
    ?:  =('' op-id)  $(ml t.ml)
    =/  desc=@t  (get-json-string op 'summary')
    =?  desc  =('' desc)  (get-json-string op 'description')
    ::  skip streaming/webhook by tag
    =/  skip=?
      =/  tags=(unit json)  (~(get by p.op) 'tags')
      ?~  tags  %.n
      ?.  ?=(%a -.u.tags)  %.n
      %+  lien  p.u.tags
      |=  tag=json
      ?.  ?=(%s -.tag)  %.n
      =/  lo=tape  (cass (trip p.tag))
      ?|  !=(~ (find "stream" lo))
          !=(~ (find "webhook" lo))
      ==
    ?:  skip  $(ml t.ml)
    ::  build tool with empty schema (params added later if needed)
    =/  tool=json
      %-  pairs:enjs:format
      :~  ['name' s+op-id]
          ['description' s+desc]
          :-  'inputSchema'
          %-  pairs:enjs:format
          :~  ['type' s+'object']
              ['properties' [%o ~]]
              ['required' a+~]
          ==
      ==
    [tool $(ml t.ml)]
  $(items t.items, result (weld path-tools result))
::
::  find an OpenAPI operation by operationId and return [path method operation]
::
++  find-operation
  |=  [spec=json op-id=@t]
  ^-  (unit [path=@t method=@t operation=json])
  =/  kind=@t  (get-json-string spec 'kind')
  ?:  =(kind 'discovery#restDescription')
    (find-discovery-operation spec op-id)
  =/  paths=json  (get-json-field spec 'paths')
  ?.  ?=(%o -.paths)  ~
  =/  items=(list [@t json])  ~(tap by p.paths)
  |-
  ?~  items  ~
  =/  [path-str=@t path-item=json]  i.items
  ?.  ?=(%o -.path-item)
    $(items t.items)
  =/  methods=(list [@t json])  ~(tap by p.path-item)
  =/  found=(unit [path=@t method=@t operation=json])
    =/  ml=(list [@t json])  methods
    |-
    ?~  ml  ~
    =/  [m=@t op=json]  i.ml
    ?.  (~(has in http-methods) m)  $(ml t.ml)
    ?.  ?=(%o -.op)  $(ml t.ml)
    =/  this-id=@t  (get-json-string op 'operationId')
    ?:  =(this-id op-id)  `[path-str m op]
    $(ml t.ml)
  ?^  found  found
  $(items t.items)
::
::  build an HTTP request URL from an OpenAPI path template + args
::
++  find-discovery-operation
  |=  [spec=json op-id=@t]
  ^-  (unit [path=@t method=@t operation=json])
  =/  resources=json  (get-json-field spec 'resources')
  ?~  resources  ~
  ?.  ?=(%o -.resources)  ~
  (search-discovery-resources resources op-id)
::
++  search-discovery-resources
  |=  [resources=json op-id=@t]
  ^-  (unit [path=@t method=@t operation=json])
  ?~  resources  ~
  ?.  ?=(%o -.resources)  ~
  =/  items=(list [@t json])  ~(tap by p.resources)
  |-
  ?~  items  ~
  =/  [rname=@t robj=json]  i.items
  ?~  robj  $(items t.items)
  ?.  ?=(%o -.robj)  $(items t.items)
  ::  check methods
  =/  methods=json  (get-json-field robj 'methods')
  =/  found=(unit [path=@t method=@t operation=json])
    ?~  methods  ~
    ?.  ?=(%o -.methods)  ~
    =/  ml=(list [@t json])  ~(tap by p.methods)
    |-
    ?~  ml  ~
    =/  [mname=@t mobj=json]  i.ml
    ?~  mobj  $(ml t.ml)
    ?.  ?=(%o -.mobj)  $(ml t.ml)
    =/  mid=@t  (get-json-string mobj 'id')
    ?.  =(mid op-id)  $(ml t.ml)
    =/  http-method=@t  (get-json-string mobj 'httpMethod')
    =/  mpath=@t
      =/  fp=@t  (get-json-string mobj 'flatPath')
      ?:(=('' fp) (get-json-string mobj 'path') fp)
    `[mpath http-method mobj]
  ?^  found  found
  ::  recurse sub-resources
  =/  sub=json  (get-json-field robj 'resources')
  =/  sub-found=(unit [path=@t method=@t operation=json])
    ?~  sub  ~
    ?.  ?=(%o -.sub)  ~
    (search-discovery-resources sub op-id)
  ?^  sub-found  sub-found
  $(items t.items)
::
++  build-api-url
  |=  [base=@t path-template=@t args=json]
  ^-  @t
  ::  substitute {param} in the path with values from args
  =/  base-t=tape  (trip base)
  ::  strip trailing / from base
  =?  base-t  &(!=(~ base-t) =('/' (rear base-t)))
    (snip base-t)
  =/  path-t=tape  (trip path-template)
  ::  ensure a '/' separator between base and path. discovery spec
  ::  paths (e.g. "users/{userId}/profile") omit the leading slash.
  =?  path-t  &(!=(~ path-t) !=('/' -.path-t))
    ['/' path-t]
  =/  result=tape  base-t
  =/  i=@ud  0
  |-
  ?:  (gte i (lent path-t))
    (crip result)
  =/  c=@  (snag i path-t)
  ?.  =(c '{')
    $(result (snoc result c), i +(i))
  ::  find closing }
  =/  rest=tape  (slag +(i) path-t)
  =/  close=(unit @ud)  (find "}" rest)
  ?~  close
    $(result (snoc result c), i +(i))
  =/  param-name=@t  (crip (scag u.close rest))
  =/  param-val=@t  (get-json-string args param-name)
  =/  val-tape=tape  (trip param-val)
  $(result (weld result val-tape), i (add i (add 2 u.close)))
::
::  build query string from OpenAPI params + args
::
++  build-query-string
  |=  [params=(list json) args=json]
  ^-  @t
  ?.  ?=(%o -.args)  ''
  =/  query-parts=(list @t)
    %+  murn  params
    |=  param=json
    ?.  ?=(%o -.param)  ~
    =/  pin=@t  (get-json-string param 'in')
    ?.  =(pin 'query')  ~
    =/  pname=@t  (get-json-string param 'name')
    =/  val=(unit json)  (~(get by p.args) pname)
    ?~  val  ~
    ?.  ?=(%s -.u.val)  ~
    ?:  =('' p.u.val)  ~
    `(cat 3 pname (cat 3 '=' p.u.val))
  ?~  query-parts  ''
  =/  result=@t  i.query-parts
  =/  rest=(list @t)  t.query-parts
  |-
  ?~  rest  (cat 3 '?' result)
  $(result (cat 3 result (cat 3 '&' i.rest)), rest t.rest)
::
++  get-spec-base-url
  |=  spec=json
  ^-  @t
  =/  kind=@t  (get-json-string spec 'kind')
  ?:  =(kind 'discovery#restDescription')
    ::  Google Discovery: use baseUrl or rootUrl
    =/  base=@t  (get-json-string spec 'baseUrl')
    ?:(=('' base) (get-json-string spec 'rootUrl') base)
  ::  OpenAPI: use servers[0].url
  =/  servers=json  (get-json-field spec 'servers')
  ?.  ?=(%a -.servers)  ''
  ?~  p.servers  ''
  (get-json-string i.p.servers 'url')
::
++  apply-tool-filter
  |=  [sid=server-id:mcp-proxy tools=(list json) filters=(map server-id:mcp-proxy tool-filter:mcp-proxy)]
  ^-  (list json)
  =/  filt=(unit tool-filter:mcp-proxy)  (~(get by filters) sid)
  ?~  filt  tools
  %+  skim  tools
  |=  tool=json
  =/  tool-name=@t  (get-json-string tool 'name')
  ?-  mode.u.filt
    %allow  (~(has in tools.u.filt) tool-name)
    %block  !(~(has in tools.u.filt) tool-name)
  ==
::
++  extract-path-params
  |=  path-template=@t
  ^-  (set @t)
  =/  t=tape  (trip path-template)
  =/  result=(set @t)  ~
  |-
  ?~  t  result
  ?.  =(i.t '{')  $(t t.t)
  =/  rest=tape  t.t
  =/  close=(unit @ud)  (find "}" rest)
  ?~  close  result
  =/  param=@t  (crip (scag u.close rest))
  $(t (slag +(u.close) rest), result (~(put in result) param))
::
++  build-all-args-query
  |=  [args=json exclude=(set @t)]
  ^-  @t
  ?.  ?=(%o -.args)  ''
  =/  items=(list [@t json])  ~(tap by p.args)
  =/  parts=(list @t)
    %+  murn  items
    |=  [key=@t val=json]
    ^-  (unit @t)
    ?:  (~(has in exclude) key)  ~
    ::  skip null values — json `~` is the atom 0 and crashes -.val
    ?~  val  ~
    =/  v=@t
      ?+  -.val  ''
        %s  p.val
        %n  p.val
        %b  ?:(p.val 'true' 'false')
      ==
    ?:  =('' v)  ~
    `(cat 3 key (cat 3 '=' v))
  ?~  parts  ''
  =/  result=@t  i.parts
  =/  rest=(list @t)  t.parts
  |-
  ?~  rest  (cat 3 '?' result)
  $(result (cat 3 result (cat 3 '&' i.rest)), rest t.rest)
::
++  get-optional-string
  |=  [jon=json key=@t]
  ^-  (unit @t)
  ?.  ?=(%o -.jon)  ~
  =/  v=(unit json)  (~(get by p.jon) key)
  ?~  v  ~
  ?.  ?=(%s -.u.v)  ~
  ?:  =('' p.u.v)  ~
  `p.u.v
::
++  get-optional-tas
  |=  [jon=json key=@t]
  ^-  (unit @tas)
  ?.  ?=(%o -.jon)  ~
  =/  v=(unit json)  (~(get by p.jon) key)
  ?~  v  ~
  ?.  ?=(%s -.u.v)  ~
  ?:  =('' p.u.v)  ~
  ``@tas`p.u.v
::
++  get-oauth-header
  |=  [oauth-prov=(unit @tas) our=@p now=@da]
  ^-  (unit [key=@t value=@t])
  ?~  oauth-prov  ~
  ::  use the auth-header scry which checks expiry
  =/  hdr=@t
    =/  res  (mule |.(.^(@t %gx /(scot %p our)/oauth/(scot %da now)/auth-header/[u.oauth-prov]/noun)))
    ?:(?=(%& -.res) p.res '')
  ?:  =('' hdr)  ~
  `['authorization' hdr]
::
++  strip-sse
  |=  body=@t
  ^-  @t
  =/  t=tape  (trip body)
  ?.  =("data: " (scag 6 t))  body
  =/  rest=tape  (slag 6 t)
  ::  trim trailing whitespace/newlines by flipping and dropping
  %-  crip  %-  flop
  =/  r=tape  (flop rest)
  |-  ^-  tape
  ?~  r  ~
  ?:  ?|(=(10 i.r) =(13 i.r) =(32 i.r))
    $(r t.r)
  r
::
++  get-base-url
  |=  url=@t
  ^-  @t
  =/  t=tape  (trip url)
  =/  scheme-mark=(unit @ud)  (find "://" t)
  ?~  scheme-mark  url
  =/  after-scheme=@ud  (add 3 u.scheme-mark)
  =/  rest=tape  (slag after-scheme t)
  =/  path-start=(unit @ud)  (find "/" rest)
  ?~  path-start  url
  (crip (scag (add after-scheme u.path-start) t))
::
++  get-json-field
  |=  [jon=json key=@t]
  ^-  json
  ?~  jon  ~
  ?.  ?=(%o -.jon)  ~
  (fall (~(get by p.jon) key) ~)
::
++  get-json-string
  |=  [jon=json key=@t]
  ^-  @t
  =/  v=json  (get-json-field jon key)
  ?~  v  ''
  ?:  ?=(%s -.v)  p.v
  ?:  ?=(%n -.v)  p.v
  ?:  ?=(%b -.v)  ?:(p.v 'true' 'false')
  ''
::
++  split-on-underscore
  |=  name=@t
  ^-  [@t @t]
  =/  t=tape  (trip name)
  =/  idx=(unit @ud)  (find "_" t)
  ?~  idx  [name '']
  [(crip (scag u.idx t)) (crip (slag +(u.idx) t))]
::
++  parse-json-action
  |=  jon=json
  ^-  (unit action:mcp-proxy)
  =/  res  (mule |.((parse-json-action-raw jon)))
  ?:  ?=(%& -.res)  `p.res
  ~
::
++  parse-json-action-raw
  |=  jon=json
  ^-  action:mcp-proxy
  =,  dejs:format
  =/  typ=@t  ((ot ~[action+so]) jon)
  ?+  typ  !!
      %'add-server'
    =/  f
      %-  ot
      :~  id+so  name+so  url+so
          headers+(ar (ot ~[key+so value+so]))
      ==
    =/  [id=@t name=@t url=@t headers=(list header:mcp-proxy)]  (f jon)
    =/  oprov=(unit @tas)  (get-optional-tas jon 'oauth-provider')
    =/  surl=(unit @t)  (get-optional-string jon 'schema-url')
    =/  md=server-mode:mcp-proxy
      =/  m=@t  (get-json-string jon 'mode')
      ?:(=('openapi' m) %openapi %proxy)
    [%add-server `@tas`id [name url headers %.y oprov md surl]]
      %'remove-server'
    [%remove-server `@tas`((ot ~[id+so]) jon)]
      %'update-server'
    =/  f
      %-  ot
      :~  id+so  name+so  url+so
          headers+(ar (ot ~[key+so value+so]))
          enabled+bo
      ==
    =/  [id=@t name=@t url=@t headers=(list header:mcp-proxy) enabled=?]  (f jon)
    =/  oprov=(unit @tas)  (get-optional-tas jon 'oauth-provider')
    =/  surl=(unit @t)  (get-optional-string jon 'schema-url')
    =/  md=server-mode:mcp-proxy
      =/  m=@t  (get-json-string jon 'mode')
      ?:(=('openapi' m) %openapi %proxy)
    [%update-server `@tas`id [name url headers enabled oprov md surl]]
      %'toggle-server'
    [%toggle-server `@tas`((ot ~[id+so]) jon)]
      %'refresh-spec'
    [%refresh-spec `@tas`((ot ~[id+so]) jon)]
      %'set-tool-filter'
    =/  id=@t  (get-json-string jon 'id')
    =/  fmode=@t  (get-json-string jon 'mode')
    =/  tool-list=(list json)
      =/  v=json  (get-json-field jon 'tools')
      ?.  ?=(%a -.v)  ~
      p.v
    =/  tool-set=(set @t)
      %-  silt
      %+  murn  tool-list
      |=(j=json ?.(?=(%s -.j) ~ `p.j))
    [%set-tool-filter `@tas`id [?:(?=(%'allow' fmode) %allow %block) tool-set]]
      %'clear-tool-filter'
    [%clear-tool-filter `@tas`((ot ~[id+so]) jon)]
      %'login-server'
    [%login-server `@tas`((ot ~[id+so]) jon)]
      %'set-client-key'
    [%set-client-key (get-json-string jon 'key')]
      %'regenerate-client-key'
    [%regenerate-client-key ~]
      %'clear-client-key'
    [%clear-client-key ~]
  ==
::
++  server-to-json
  |=  [sid=server-id:mcp-proxy srv=mcp-server:mcp-proxy]
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  ['id' s+(scot %tas sid)]
      ['name' s+name.srv]
      ['url' s+url.srv]
      ['enabled' b+enabled.srv]
      :-  'headers'  :-  %a
      %+  turn  headers.srv
      |=  h=header:mcp-proxy
      (pairs ~[['key' s+key.h] ['value' s+value.h]])
  ==
::
++  give-http
  |=  [eyre-id=@ta status=@ud headers=(list [@t @t]) body=(unit octs)]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  [[status headers] body]
::
++  give-json
  |=  [eyre-id=@ta jon=json]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  (json-response:gen:server jon)
--
