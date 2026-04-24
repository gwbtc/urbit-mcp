::  oauth: OAuth 2.0 + PKCE token management agent
::
::    manages provider configs, handles browser auth flows,
::    stores tokens, auto-refreshes before expiry.
::    other agents scry or subscribe for tokens.
::
/-  oauth
/+  default-agent, dbug, server
|%
+$  card  card:agent:gall
--
::
%-  agent:dbug
=|  state-0:oauth
=*  state  -
=/  refreshing  *(set provider-id:oauth)  ::  in-flight refresh locks (non-persisted)
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /oauth] %oauth]
  ==
::
++  on-save  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  =/  old  (mule |.(!<(versioned-state:oauth old-state)))
  ?:  ?=(%| -.old)
    on-init
  ?-  -.p.old
      %0
    ::  re-register refresh timers for all grants with expiry
    =/  eyre-cards=(list card)
      :~  [%pass /eyre/connect %arvo %e %connect [~ /oauth] %oauth]
      ==
    =/  timer-cards=(list card)
      %+  murn  ~(tap by grants.p.old)
      |=  [pid=provider-id:oauth gra=grant:oauth]
      ?~  expires-at.gra  ~
      ?~  refresh-token.gra  ~
      =/  refresh-time=@da
        =/  margin=@dr  ~m5
        ?:  (gth u.expires-at.gra (add now.bowl margin))
          (sub u.expires-at.gra margin)
        (add now.bowl ~s5)
      `[%pass /timer/refresh/[pid] %arvo %b %wait refresh-time]
    :_  this(state p.old)
    (weld eyre-cards timer-cards)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^
  ?+  mark  (on-poke:def mark vase)
      %oauth-action
    (handle-action !<(action:oauth vase))
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    (handle-http eyre-id req)
  ==
  ::
  ++  handle-action
    |=  act=action:oauth
    ^-  (quip card _this)
    ?>  =(our src):bowl
    ?-  -.act
    ::
        %add-provider
      ?:  (~(has by providers) id.act)
        ~|(%oauth-provider-exists !!)
      =.  providers  (~(put by providers) id.act config.act)
      `this
    ::
        %remove-provider
      =.  providers  (~(del by providers) id.act)
      =.  grants     (~(del by grants) id.act)
      `this
    ::
        %update-provider
      ::  preserve existing client-secret if the new one is empty
      =/  existing=(unit provider-config:oauth)  (~(get by providers) id.act)
      =/  new-cfg=provider-config:oauth  config.act
      =?  new-cfg  ?&(?=(^ existing) =('' client-secret.new-cfg))
        new-cfg(client-secret client-secret.u.existing)
      =.  providers  (~(put by providers) id.act new-cfg)
      `this
    ::
        %connect
      =/  cfg=(unit provider-config:oauth)  (~(get by providers) id.act)
      ?~  cfg
        ~|(%oauth-provider-not-found !!)
      ::  generate PKCE verifier and state
      ::
      =/  raw-eny=@  eny.bowl
      =/  state-param=@t  (scot %uv `@uv`raw-eny)
      =/  verifier=@t  (make-verifier raw-eny)
      =/  challenge=@t  (make-challenge verifier)
      ::  store pending auth
      ::
      =/  pend=pending-auth:oauth
        [state-param verifier id.act]
      =.  pending  (~(put by pending) state-param pend)
      ::  build auth URL
      ::
      =/  auth=@t
        %+  build-auth-url  u.cfg
        [state-param challenge]
      ::  return the URL as a JSON response via fact on /redirects
      ::
      :_  this
      :~  [%give %fact [/redirects]~ %json !>((frond:enjs:format 'url' s+auth))]
      ==
    ::
        %disconnect
      =/  had=?  (~(has by grants) id.act)
      =.  grants  (~(del by grants) id.act)
      ?.  had  `this
      :_  this
      :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%grant-removed id.act])]
      ==
    ::
        %force-refresh
      ::  trigger immediate token refresh (called by %mcp-proxy on 401)
      =/  gra=(unit grant:oauth)  (~(get by grants) id.act)
      ?~  gra  `this
      ?~  refresh-token.u.gra  `this
      ?:  (~(has in refreshing) id.act)  `this
      =/  cfg=(unit provider-config:oauth)  (~(get by providers) id.act)
      ?~  cfg  `this
      =.  refreshing  (~(put in refreshing) id.act)
      =/  body=@t
        %+  rap  3
        :~  'grant_type=refresh_token'
            '&refresh_token='
            u.refresh-token.u.gra
        ==
      =/  basic-auth=@t  (make-basic-auth client-id.u.cfg client-secret.u.cfg)
      ~&  [%oauth %force-refresh id.act]
      :_  this
      :~  :*  %pass  /iris/token-refresh/[id.act]
              %arvo  %i  %request
              :*  %'POST'
                  token-url.u.cfg
                  :~  ['content-type' 'application/x-www-form-urlencoded']
                      ['accept' 'application/json']
                      ['authorization' basic-auth]
                  ==
                  `(as-octs:mimes:html body)
              ==
              *outbound-config:iris
          ==
      ==
    ::
        %revoke
      =/  gra=(unit grant:oauth)  (~(get by grants) id.act)
      ?~  gra
        ~|(%oauth-no-grant !!)
      =/  cfg=(unit provider-config:oauth)  (~(get by providers) id.act)
      ?~  cfg
        ~|(%oauth-provider-not-found !!)
      ?~  revoke-url.u.cfg
        ::  no revoke endpoint, just disconnect
        ::
        =.  grants  (~(del by grants) id.act)
        :_  this
        :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%grant-removed id.act])]
        ==
      ::  POST revoke request
      ::
      =/  body=@t
        %+  rap  3
        :~  'token='
            access-token.u.gra
            '&client_id='
            client-id.u.cfg
        ==
      :_  this
      :~  :*  %pass  /iris/revoke/[id.act]
              %arvo  %i  %request
              :*  %'POST'
                  u.revoke-url.u.cfg
                  ~[['content-type' 'application/x-www-form-urlencoded']]
                  `(as-octs:mimes:html body)
              ==
              *outbound-config:iris
          ==
      ==
    ==
  ::
  ::  HTTP request handler
  ::
  ++  handle-http
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  rl=request-line:server  (parse-request-line:server url.request.req)
    =/  site=(list @t)  site.rl
    ::  /oauth/callback — handle OAuth redirect
    ::
    ?:  ?=([%oauth %callback *] site)
      (handle-callback eyre-id req)
    ::  /oauth/api/* — JSON API
    ::
    ?:  ?=([%oauth %api *] site)
      ?.  authenticated.req
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        (login-redirect:gen:server request.req)
      (handle-api eyre-id req t.t.site)
    ::  /oauth or /oauth/ — redirect to main MCP proxy UI
    ::
    ?:  ?|  ?=([%oauth ~] site)
            ?=([%oauth %$ ~] site)
        ==
      :_  this
      (give-http eyre-id 307 ~[['location' '/apps/mcp/']] ~)
    ::  /oauth/manage — old direct UI (kept for backward compat)
    ?:  ?=([%oauth %manage ~] site)
      ?.  authenticated.req
        :_  this
        %+  give-simple-payload:app:server  eyre-id
        (login-redirect:gen:server request.req)
      :_  this
      (give-http eyre-id 200 ~[['content-type' 'text/html']] (some (as-octs:mimes:html index-html)))
    ::  /oauth/css/app.css
    ::
    ?:  ?=([%oauth %css %app ~] site)
      :_  this
      (give-http eyre-id 200 ~[['content-type' 'text/css']] (some (as-octs:mimes:html app-css)))
    ::  /oauth/js/*
    ::
    ?:  ?=([%oauth %js %app ~] site)
      :_  this
      (give-http eyre-id 200 ~[['content-type' 'application/javascript']] (some (as-octs:mimes:html app-js)))
    ?:  ?=([%oauth %js %api ~] site)
      :_  this
      (give-http eyre-id 200 ~[['content-type' 'application/javascript']] (some (as-octs:mimes:html api-js)))
    ::  404
    ::
    :_  this
    (give-http eyre-id 404 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'not found')))
  ::
  ::  handle OAuth callback from provider
  ::
  ++  handle-callback
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  rl=request-line:server  (parse-request-line:server url.request.req)
    =/  params=(list [key=@t value=@t])  args.rl
    =/  code=(unit @t)   (get-param params 'code')
    =/  st=(unit @t)     (get-param params 'state')
    ::  validate params
    ::
    ?~  code
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'text/html']] (some (as-octs:mimes:html '<h1>Error: missing code parameter</h1>')))
    ?~  st
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'text/html']] (some (as-octs:mimes:html '<h1>Error: missing state parameter</h1>')))
    ::  look up pending auth
    ::
    =/  pend=(unit pending-auth:oauth)  (~(get by pending) u.st)
    ?~  pend
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'text/html']] (some (as-octs:mimes:html '<h1>Error: unknown state parameter (expired or invalid)</h1>')))
    ::  look up provider config
    ::
    =/  cfg=(unit provider-config:oauth)  (~(get by providers) provider-id.u.pend)
    ?~  cfg
      =.  pending  (~(del by pending) u.st)
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'text/html']] (some (as-octs:mimes:html '<h1>Error: provider no longer configured</h1>')))
    ::  build token exchange request
    ::
    =/  body=@t
      %+  rap  3
      :~  'grant_type=authorization_code'
          '&code='
          u.code
          '&redirect_uri='
          redirect-uri.u.cfg
          '&code_verifier='
          verifier.u.pend
      ==
    =/  basic-auth=@t  (make-basic-auth client-id.u.cfg client-secret.u.cfg)
    ::  send token exchange via iris, serve wait page
    ::
    :_  this
    %+  weld
      :~  :*  %pass  /iris/token-exchange/[u.st]
              %arvo  %i  %request
              :*  %'POST'
                  token-url.u.cfg
                  :~  ['content-type' 'application/x-www-form-urlencoded']
                      ['accept' 'application/json']
                      ['authorization' basic-auth]
                  ==
                  `(as-octs:mimes:html body)
              ==
              *outbound-config:iris
          ==
      ==
    (give-http eyre-id 200 ~[['content-type' 'text/html']] (some (as-octs:mimes:html callback-html)))
  ::
  ::  JSON API handler
  ::
  ++  handle-api
    |=  [eyre-id=@ta req=inbound-request:eyre site=(list @t)]
    ^-  (quip card _this)
    ?:  =(%'GET' method.request.req)
      ?+  site
        :_  this
        (give-http eyre-id 404 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'not found')))
      ::
          [%providers ~]
        :_  this
        (give-json eyre-id (build-providers-json ~))
      ::
          [%grants ~]
        :_  this
        (give-json eyre-id (build-grants-json ~))
      ==
    ?:  =(%'POST' method.request.req)
      =/  body=@t
        ?~  body.request.req  ''
        `@t`q.u.body.request.req
      =/  jon=(unit json)  (de:json:html body)
      ?~  jon
        :_  this
        (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"bad json"}')))
      =/  act=(unit action:oauth)  (action-from-json u.jon)
      ?~  act
        :_  this
        (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"bad action"}')))
      ::  special handling for %connect: return auth URL in response
      ::
      ?:  ?=(%connect -.u.act)
        =/  cfg=(unit provider-config:oauth)  (~(get by providers) id.u.act)
        ?~  cfg
          :_  this
          (give-http eyre-id 404 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"provider not found"}')))
        =/  raw-eny=@  eny.bowl
        =/  state-param=@t  (scot %uv `@uv`raw-eny)
        =/  verifier=@t  (make-verifier raw-eny)
        =/  challenge=@t  (make-challenge verifier)
        =/  pend=pending-auth:oauth  [state-param verifier id.u.act]
        =.  pending  (~(put by pending) state-param pend)
        =/  auth=@t  (build-auth-url u.cfg [state-param challenge])
        =/  resp=@t  (en:json:html (frond:enjs:format 'url' s+auth))
        :_  this
        (give-http eyre-id 200 ~[['content-type' 'application/json']] (some (as-octs:mimes:html resp)))
      ::  all other actions
      ::
      =/  result  (handle-action u.act)
      :_  +.result
      %+  weld  -.result
      (give-http eyre-id 200 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"ok":true}')))
    :_  this
    (give-http eyre-id 405 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'method not allowed')))
  --
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
      [%http-response @ ~]
    `this
  ::
      [%grants ~]
    ?>  =(our.bowl src.bowl)
    ::  send initial grant state
    ::
    :_  this
    %+  turn  ~(tap by grants)
    |=  [pid=provider-id:oauth gra=grant:oauth]
    [%give %fact ~ %oauth-update !>(`update:oauth`[%grant-added pid gra])]
  ::
      [%redirects ~]
    `this
  ==
::
++  on-agent  on-agent:def
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  `this
  ::
      [%eyre *]
    ?:  ?=(%bound +<.sign)
      ~?  !accepted.sign  [%oauth %binding-rejected binding.sign]
      `this
    `this
  ::
  ::  token exchange response
  ::
      [%iris %token-exchange @ ~]
    =/  st=@t  i.t.t.wire
    ?.  ?=([%iris %http-response *] sign)
      ~&  [%oauth %token-exchange-failed st %bad-sign]
      `this
    =/  resp=client-response:iris  client-response.sign
    ?.  ?=(%finished -.resp)
      ~&  [%oauth %token-exchange-failed st %not-finished]
      `this
    ?.  =(200 status-code.response-header.resp)
      ~&  [%oauth %token-exchange-failed st %status status-code.response-header.resp]
      =.  pending  (~(del by pending) st)
      `this
    ?~  full-file.resp
      ~&  [%oauth %token-exchange-failed st %no-body]
      =.  pending  (~(del by pending) st)
      `this
    =/  body=@t  `@t`q.data.u.full-file.resp
    =/  jon=(unit json)  (de:json:html body)
    ?~  jon
      ~&  [%oauth %token-exchange-failed st %bad-json]
      =.  pending  (~(del by pending) st)
      `this
    ::  parse token response
    ::
    =/  pend=(unit pending-auth:oauth)  (~(get by pending) st)
    ?~  pend
      ~&  [%oauth %token-exchange-failed st %no-pending]
      `this
    =/  gra=(unit grant:oauth)  (parse-token-response u.jon provider-id.u.pend now.bowl)
    ?~  gra
      ~&  [%oauth %token-exchange-failed st %parse-failed]
      =.  pending  (~(del by pending) st)
      `this
    ::  store grant, clear pending
    ::
    =.  grants   (~(put by grants) provider-id.u.pend u.gra)
    =.  pending  (~(del by pending) st)
    ::  notify subscribers + set refresh timer
    ::
    =/  cards=(list card)
      :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%grant-added provider-id.u.pend u.gra])]
      ==
    =?  cards  ?=(^ expires-at.u.gra)
      =/  refresh-time=@da
        =/  exp=@da  u.expires-at.u.gra
        =/  margin=@dr  ~m5
        ?:  (gth exp (add now.bowl margin))
          (sub exp margin)
        (add now.bowl ~s30)
      (snoc cards [%pass /timer/refresh/[provider-id.u.pend] %arvo %b %wait refresh-time])
    [cards this]
  ::
  ::  token refresh response
  ::
      [%iris %token-refresh @ ~]
    =/  pid=provider-id:oauth  i.t.t.wire
    =.  refreshing  (~(del in refreshing) pid)
    ?.  ?=([%iris %http-response *] sign)
      ~&  [%oauth %refresh-failed pid %bad-sign]
      `this
    =/  resp=client-response:iris  client-response.sign
    ?.  ?=(%finished -.resp)
      ~&  [%oauth %refresh-failed pid %not-finished]
      `this
    ?.  =(200 status-code.response-header.resp)
      ::  check for invalid_grant (requires re-auth, not retry)
      =/  err-body=@t
        ?~  full-file.resp  ''
        `@t`q.data.u.full-file.resp
      =/  is-invalid=?
        !=(~ (find "invalid_grant" (trip err-body)))
      ~&  [%oauth %refresh-failed pid %status status-code.response-header.resp ?:(is-invalid %invalid-grant %other)]
      ::  remove grant if invalid_grant (forces re-auth)
      =?  grants  is-invalid  (~(del by grants) pid)
      :_  this
      :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%token-expired pid])]
      ==
    ?~  full-file.resp
      ~&  [%oauth %refresh-failed pid %no-body]
      `this
    =/  body=@t  `@t`q.data.u.full-file.resp
    =/  jon=(unit json)  (de:json:html body)
    ?~  jon
      ~&  [%oauth %refresh-failed pid %bad-json]
      `this
    =/  gra=(unit grant:oauth)  (parse-token-response u.jon pid now.bowl)
    ?~  gra
      ~&  [%oauth %refresh-failed pid %parse-failed]
      :_  this
      :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%token-expired pid])]
      ==
    ::  preserve refresh token if new one not provided
    ::
    =/  old=(unit grant:oauth)  (~(get by grants) pid)
    =/  final=grant:oauth
      ?:  &(?=(^ old) ?=(~ refresh-token.u.gra))
        u.gra(refresh-token refresh-token.u.old)
      u.gra
    =.  grants  (~(put by grants) pid final)
    =/  cards=(list card)
      :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%grant-refreshed pid final])]
      ==
    =?  cards  ?=(^ expires-at.final)
      =/  refresh-time=@da
        =/  exp=@da  u.expires-at.final
        =/  margin=@dr  ~m5
        ?:  (gth exp (add now.bowl margin))
          (sub exp margin)
        (add now.bowl ~s30)
      (snoc cards [%pass /timer/refresh/[pid] %arvo %b %wait refresh-time])
    [cards this]
  ::
  ::  revoke response
  ::
      [%iris %revoke @ ~]
    =/  pid=provider-id:oauth  i.t.t.wire
    =.  grants  (~(del by grants) pid)
    :_  this
    :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%grant-removed pid])]
    ==
  ::
  ::  refresh timer
  ::
      [%timer %refresh @ ~]
    =/  pid=provider-id:oauth  i.t.t.wire
    ?.  ?=([%behn %wake *] sign)  `this
    ::  single-flight: skip if already refreshing
    ?:  (~(has in refreshing) pid)  `this
    =/  gra=(unit grant:oauth)  (~(get by grants) pid)
    ?~  gra  `this
    ?~  refresh-token.u.gra
      :_  this
      :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%token-expired pid])]
      ==
    =/  cfg=(unit provider-config:oauth)  (~(get by providers) pid)
    ?~  cfg
      :_  this
      :~  [%give %fact [/grants]~ %oauth-update !>(`update:oauth`[%token-expired pid])]
      ==
    =.  refreshing  (~(put in refreshing) pid)
    =/  body=@t
      %+  rap  3
      :~  'grant_type=refresh_token'
          '&refresh_token='
          u.refresh-token.u.gra
      ==
    =/  basic-auth=@t  (make-basic-auth client-id.u.cfg client-secret.u.cfg)
    :_  this
    :~  :*  %pass  /iris/token-refresh/[pid]
            %arvo  %i  %request
            :*  %'POST'
                token-url.u.cfg
                :~  ['content-type' 'application/x-www-form-urlencoded']
                    ['accept' 'application/json']
                    ['authorization' basic-auth]
                ==
                `(as-octs:mimes:html body)
            ==
            *outbound-config:iris
        ==
    ==
  ==
::
++  on-leave  on-leave:def
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?>  =(our src):bowl
  ?+  path  [~ ~]
      [%x %grant @ ~]
    =/  pid=provider-id:oauth  `@tas`i.t.t.path
    =/  gra=(unit grant:oauth)  (~(get by grants) pid)
    ?~  gra  [~ ~]
    ``noun+!>(u.gra)
  ::
      [%x %providers ~]
    ``noun+!>(providers)
  ::
      [%x %has-grant @ ~]
    =/  pid=provider-id:oauth  `@tas`i.t.t.path
    ``noun+!>((~(has by grants) pid))
  ::
      ::  /x/token/<provider-id>: get access token as @t
      ::  returns the token if valid, or '' if expired/missing
      ::  callers should poke %oauth with %connect if '' is returned
      ::
      [%x %token @ ~]
    =/  pid=provider-id:oauth  `@tas`i.t.t.path
    =/  gra=(unit grant:oauth)  (~(get by grants) pid)
    ?~  gra  ``noun+!>(`@t`'')
    ::  check if expired
    ?:  ?&  ?=(^ expires-at.u.gra)
            (lth u.expires-at.u.gra now.bowl)
        ==
      ``noun+!>(`@t`'')
    ``noun+!>(access-token.u.gra)
  ::
      ::  /x/auth-header/<provider-id>: get full Authorization header
      ::  e.g. "Bearer xxx" - ready to use as header value
      ::
      [%x %auth-header @ ~]
    =/  pid=provider-id:oauth  `@tas`i.t.t.path
    =/  gra=(unit grant:oauth)  (~(get by grants) pid)
    ?~  gra  ``noun+!>(`@t`'')
    ?:  ?&  ?=(^ expires-at.u.gra)
            (lth u.expires-at.u.gra now.bowl)
        ==
      ``noun+!>(`@t`'')
    ``noun+!>((rap 3 ~[token-type.u.gra ' ' access-token.u.gra]))
  ==
::
++  on-fail  on-fail:def
--
::
::  helper core
::
|%
::
::  PKCE helpers
::
++  make-basic-auth
  |=  [client-id=@t client-secret=@t]
  ^-  @t
  =/  creds=@t  (rap 3 ~[client-id ':' client-secret])
  =/  encoded=@t  (en:base64:mimes:html [(met 3 creds) creds])
  (rap 3 ~['Basic ' encoded])
::
++  make-verifier
  |=  eny=@
  ^-  @t
  ::  generate 43-char base64url string from entropy
  ::  shax takes an atom, returns a 256-bit hash as @
  ::
  =/  raw=@  (shax eny)
  =/  b64=@t  (en:base64:mimes:html [32 raw])
  (safe-scag 43 (base64-to-url b64))
::
++  make-challenge
  |=  verifier=@t
  ^-  @t
  ::  SHA-256 hash of verifier bytes, base64url encoded
  ::  trip the cord to get bytes, then hash as atom
  ::
  =/  vt=tape  (trip verifier)
  =/  hash=@  (shax (crip vt))
  =/  b64=@t  (en:base64:mimes:html [32 hash])
  (base64-to-url b64)
::
++  base64-to-url
  |=  b64=@t
  ^-  @t
  ::  convert standard base64 to base64url:
  ::  replace + with -, / with _, strip = padding
  ::
  %-  crip
  %+  turn
    %+  skip  (trip b64)
    |=(c=@tD =(c '='))
  |=  c=@tD
  ?:  =(c '+')  '-'
  ?:  =(c '/')  '_'
  c
::
++  safe-scag
  |=  [n=@ud t=@t]
  ^-  @t
  (crip (scag n (trip t)))
::
::  URL builder
::
++  build-auth-url
  |=  [cfg=provider-config:oauth state=@t challenge=@t]
  ^-  @t
  %+  rap  3
  :~  auth-url.cfg
      '?client_id='
      client-id.cfg
      '&redirect_uri='
      redirect-uri.cfg
      '&response_type=code'
      '&state='
      state
      '&code_challenge='
      challenge
      '&code_challenge_method=S256'
      '&scope='
      scopes.cfg
  ==
::
::  query param extractor
::
++  get-param
  |=  [params=(list [key=@t value=@t]) key=@t]
  ^-  (unit @t)
  =/  match=(list [key=@t value=@t])
    (skim params |=([k=@t v=@t] =(k key)))
  ?~  match  ~
  `value.i.match
::
::  token response parser
::
++  parse-token-response
  |=  [jon=json pid=provider-id:oauth now=@da]
  ^-  (unit grant:oauth)
  =/  res  (mule |.((parse-token-json jon pid now)))
  ?:  ?=(%& -.res)  `p.res
  ~
::
++  parse-token-json
  |=  [jon=json pid=provider-id:oauth now=@da]
  ^-  grant:oauth
  ?>  ?=(%o -.jon)
  =/  at=@t
    =/  v=(unit json)  (~(get by p.jon) 'access_token')
    ?~  v  ''
    ?.  ?=(%s -.u.v)  ''
    p.u.v
  =/  rt=(unit @t)
    =/  v=(unit json)  (~(get by p.jon) 'refresh_token')
    ?~  v  ~
    ?.  ?=(%s -.u.v)  ~
    `p.u.v
  =/  tt=@t
    =/  v=(unit json)  (~(get by p.jon) 'token_type')
    ?~  v  'Bearer'
    ?.  ?=(%s -.u.v)  'Bearer'
    p.u.v
  =/  exp=(unit @da)
    =/  v=(unit json)  (~(get by p.jon) 'expires_in')
    ?~  v  ~
    ?.  ?=(%n -.u.v)  ~
    =/  secs=(unit @ud)  (slaw %ud p.u.v)
    ?~  secs  ~
    `(add now (mul u.secs ~s1))
  =/  sc=@t
    =/  v=(unit json)  (~(get by p.jon) 'scope')
    ?~  v  ''
    ?.  ?=(%s -.u.v)  ''
    p.u.v
  [at rt tt exp sc pid]
::
::  JSON action parser (for HTTP API)
::
++  action-from-json
  |=  jon=json
  ^-  (unit action:oauth)
  =/  res  (mule |.((action-from-json-raw jon)))
  ?:  ?=(%& -.res)  `p.res
  ~
::
++  action-from-json-raw
  |=  jon=json
  ^-  action:oauth
  =,  dejs:format
  =/  typ=@t  ((ot ~[action+so]) jon)
  ?+  typ  !!
      %'add-provider'
    =/  f
      %-  ot
      :~  id+so
          auth-url+so
          token-url+so
          revoke-url+(mu so)
          client-id+so
          client-secret+so
          redirect-uri+so
          scopes+so
      ==
    =/  [id=@t auth-url=@t token-url=@t revoke-url=(unit @t) client-id=@t client-secret=@t redirect-uri=@t scopes=@t]
      (f jon)
    [%add-provider `@tas`id [auth-url token-url revoke-url client-id client-secret redirect-uri scopes]]
  ::
      %'remove-provider'
    [%remove-provider `@tas`((ot ~[id+so]) jon)]
  ::
      %'connect'
    [%connect `@tas`((ot ~[id+so]) jon)]
  ::
      %'disconnect'
    [%disconnect `@tas`((ot ~[id+so]) jon)]
  ::
      %'revoke'
    [%revoke `@tas`((ot ~[id+so]) jon)]
  ::
      %'force-refresh'
    [%force-refresh `@tas`((ot ~[id+so]) jon)]
  ==
::
::  JSON builders
::
++  build-providers-json
  |=  ~
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  :-  'providers'
      :-  %a
      %+  turn  ~(tap by providers)
      |=  [pid=provider-id:oauth cfg=provider-config:oauth]
      %-  pairs
      :~  ['id' s+(scot %tas pid)]
          ['name' s+(scot %tas pid)]
          ['authUrl' s+auth-url.cfg]
          ['tokenUrl' s+token-url.cfg]
          :-  'revokeUrl'
          ?~  revoke-url.cfg  ~
          s+u.revoke-url.cfg
          ['clientId' s+client-id.cfg]
          ['redirectUri' s+redirect-uri.cfg]
          ['scopes' s+scopes.cfg]
          ['hasSecret' b+!=('' client-secret.cfg)]
          ['hasGrant' b+(~(has by grants) pid)]
      ==
  ==
::
++  build-grants-json
  |=  ~
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  :-  'grants'
      :-  %a
      %+  turn  ~(tap by grants)
      |=  [pid=provider-id:oauth gra=grant:oauth]
      %-  pairs
      :~  ['providerId' s+(scot %tas pid)]
          ['tokenType' s+token-type.gra]
          ['scopes' s+scopes.gra]
          :-  'expiresAt'
          ?~  expires-at.gra  ~
          s+(scot %da u.expires-at.gra)
          ['hasRefreshToken' b+?=(^ refresh-token.gra)]
      ==
  ==
::
::  HTTP helpers
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
::
::  static content
::
++  callback-html
  ^-  @t
  '''
  <!DOCTYPE html>
  <html>
  <head><title>OAuth - Processing</title></head>
  <body style="font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0;">
    <div style="text-align: center;">
      <h2>Authorization received</h2>
      <p>Exchanging token... you can close this tab.</p>
      <p><a href="/oauth">Back to OAuth Manager</a></p>
    </div>
  </body>
  </html>
  '''
::
++  index-html
  ^-  @t
  '''
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OAuth Manager</title>
    <link rel="stylesheet" href="/oauth/css/app.css">
  </head>
  <body>
    <div id="app">
      <header>
        <h1>OAuth Manager</h1>
        <p class="subtitle">Manage OAuth provider connections for your ship</p>
      </header>
      <main>
        <section id="add-provider">
          <h2>Add Provider</h2>
          <form id="add-form">
            <div class="form-row">
              <label>ID <input type="text" name="id" placeholder="github" pattern="[a-z][a-z0-9]*(-[a-z0-9]+)*" required></label>
              <label>Client ID <input type="text" name="client-id" placeholder="your-client-id" required></label>
            </div>
            <div class="form-row">
              <label>Client Secret <input type="password" name="client-secret" placeholder="your-client-secret" required></label>
            </div>
            <div class="form-row">
              <label>Auth URL <input type="url" name="auth-url" placeholder="https://github.com/login/oauth/authorize" required></label>
              <label>Token URL <input type="url" name="token-url" placeholder="https://github.com/login/oauth/access_token" required></label>
            </div>
            <div class="form-row">
              <label>Revoke URL (optional) <input type="url" name="revoke-url" placeholder=""></label>
              <label>Redirect URI <input type="url" name="redirect-uri" placeholder="https://yourship.tlon.network/oauth/callback" required></label>
            </div>
            <div class="form-row">
              <label>Scopes <input type="text" name="scopes" placeholder="repo user"></label>
            </div>
            <div class="form-actions">
              <button type="submit">Add Provider</button>
            </div>
          </form>
        </section>
        <section id="providers-section">
          <h2>Providers</h2>
          <div id="providers"></div>
        </section>
      </main>
    </div>
    <script src="/oauth/js/api.js"></script>
    <script src="/oauth/js/app.js"></script>
  </body>
  </html>
  '''
::
++  app-css
  ^-  @t
  '''
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; color: #1a1a1a; padding: 2rem; max-width: 720px; margin: 0 auto; }
  header { margin-bottom: 2rem; }
  h1 { font-size: 1.5rem; font-weight: 600; }
  h2 { font-size: 1.1rem; font-weight: 600; margin-bottom: 0.75rem; }
  .subtitle { color: #666; font-size: 0.85rem; margin-top: 0.25rem; }
  section { background: #fff; border: 1px solid #e0e0e0; border-radius: 8px; padding: 1.25rem; margin-bottom: 1.5rem; }
  .form-row { display: flex; gap: 0.75rem; margin-bottom: 0.75rem; }
  .form-row label { flex: 1; display: flex; flex-direction: column; font-size: 0.8rem; color: #555; gap: 0.25rem; }
  input { padding: 0.5rem; border: 1px solid #ccc; border-radius: 4px; font-size: 0.85rem; }
  button { padding: 0.5rem 1rem; border: none; border-radius: 4px; cursor: pointer; font-size: 0.85rem; background: #1a1a1a; color: #fff; }
  button:hover { background: #333; }
  button.secondary { background: #e0e0e0; color: #1a1a1a; }
  button.danger { background: #d32f2f; color: #fff; }
  button.danger:hover { background: #b71c1c; }
  button.success { background: #2e7d32; color: #fff; }
  button.success:hover { background: #1b5e20; }
  .form-actions { display: flex; gap: 0.5rem; justify-content: flex-end; }
  .provider-card { background: #fafafa; border: 1px solid #e0e0e0; border-radius: 6px; padding: 1rem; margin-bottom: 0.75rem; }
  .provider-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; }
  .provider-name { font-weight: 600; }
  .provider-url { font-size: 0.8rem; color: #666; margin-bottom: 0.5rem; }
  .provider-actions { display: flex; gap: 0.5rem; }
  .badge { font-size: 0.7rem; padding: 0.15rem 0.5rem; border-radius: 99px; font-weight: 500; }
  .badge.connected { background: #e8f5e9; color: #2e7d32; }
  .badge.disconnected { background: #fce4ec; color: #c62828; }
  .empty { color: #999; font-size: 0.85rem; text-align: center; padding: 2rem; }
  .toast { position: fixed; bottom: 1rem; right: 1rem; background: #1a1a1a; color: #fff; padding: 0.5rem 1rem; border-radius: 6px; font-size: 0.85rem; opacity: 0; transition: opacity 0.3s; }
  .toast.show { opacity: 1; }
  '''
::
++  app-js
  ^-  @t
  '''
  var OAuthApp = {
    providers: [],
    init: function() {
      this.loadProviders();
      this.bindEvents();
    },
    loadProviders: function() {
      var self = this;
      OAuthAPI.getProviders().then(function(data) {
        self.providers = data.providers || [];
        self.render();
      }).catch(function(e) {
        console.error('Failed to load providers:', e);
        self.providers = [];
        self.render();
      });
    },
    bindEvents: function() {
      var self = this;
      document.getElementById('add-form').addEventListener('submit', function(e) {
        e.preventDefault();
        var f = e.target;
        var data = {
          action: 'add-provider',
          id: f.elements['id'].value.trim().toLowerCase(),
          'auth-url': f.elements['auth-url'].value.trim(),
          'token-url': f.elements['token-url'].value.trim(),
          'revoke-url': f.elements['revoke-url'].value.trim() || null,
          'client-id': f.elements['client-id'].value.trim(),
          'client-secret': f.elements['client-secret'].value.trim(),
          'redirect-uri': f.elements['redirect-uri'].value.trim(),
          scopes: f.elements['scopes'].value.trim()
        };
        OAuthAPI.post(data).then(function() {
          f.reset();
          self.loadProviders();
          self.toast('Provider added');
        }).catch(function(e) { alert('Failed: ' + e.message); });
      });
    },
    connect: function(id) {
      var self = this;
      OAuthAPI.post({ action: 'connect', id: id }).then(function(data) {
        if (data && data.url) {
          window.location.href = data.url;
        } else {
          self.toast('Connect initiated');
          self.loadProviders();
        }
      }).catch(function(e) { alert('Connect failed: ' + e.message); });
    },
    disconnect: function(id) {
      var self = this;
      OAuthAPI.post({ action: 'disconnect', id: id }).then(function() {
        self.loadProviders();
        self.toast('Disconnected');
      }).catch(function(e) { alert('Failed: ' + e.message); });
    },
    remove: function(id) {
      if (!confirm('Remove this provider?')) return;
      var self = this;
      OAuthAPI.post({ action: 'remove-provider', id: id }).then(function() {
        self.loadProviders();
        self.toast('Provider removed');
      }).catch(function(e) { alert('Failed: ' + e.message); });
    },
    render: function() {
      var container = document.getElementById('providers');
      if (this.providers.length === 0) {
        container.innerHTML = '<div class="empty">No providers configured. Add one above.</div>';
        return;
      }
      var html = '';
      for (var i = 0; i < this.providers.length; i++) {
        var p = this.providers[i];
        var status = p.hasGrant ? 'connected' : 'disconnected';
        html += '<div class="provider-card">' +
          '<div class="provider-header">' +
            '<span class="provider-name">' + this.esc(p.id) + '</span>' +
            '<span class="badge ' + status + '">' + status + '</span>' +
          '</div>' +
          '<div class="provider-url">' + this.esc(p.authUrl) + '</div>' +
          '<div class="provider-url">Scopes: ' + this.esc(p.scopes) + '</div>' +
          '<div class="provider-actions">' +
            (p.hasGrant
              ? '<button class="danger" onclick="OAuthApp.disconnect(\'' + p.id + '\')">Disconnect</button>'
              : '<button class="success" onclick="OAuthApp.connect(\'' + p.id + '\')">Connect</button>') +
            '<button class="secondary" onclick="OAuthApp.remove(\'' + p.id + '\')">Remove</button>' +
          '</div>' +
        '</div>';
      }
      container.innerHTML = html;
    },
    toast: function(msg) {
      var el = document.getElementById('toast');
      if (!el) {
        el = document.createElement('div');
        el.id = 'toast';
        el.className = 'toast';
        document.body.appendChild(el);
      }
      el.textContent = msg;
      el.classList.add('show');
      setTimeout(function() { el.classList.remove('show'); }, 2000);
    },
    esc: function(s) {
      if (!s) return '';
      return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }
  };
  document.addEventListener('DOMContentLoaded', function() { OAuthApp.init(); });
  '''
::
++  api-js
  ^-  @t
  '''
  var OAuthAPI = {
    base: '/oauth/api',
    getProviders: function() {
      return fetch(this.base + '/providers', { credentials: 'same-origin' }).then(function(r) { return r.json(); });
    },
    getGrants: function() {
      return fetch(this.base + '/grants', { credentials: 'same-origin' }).then(function(r) { return r.json(); });
    },
    post: function(data) {
      return fetch(this.base, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      }).then(function(r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
      });
    }
  };
  '''
--
