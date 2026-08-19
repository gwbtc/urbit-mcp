/-  mcp
/+  dbug, verb, server, default-agent, pf=pretty-file,
    jut=json-utils, *rpc, beam-uri=uri-beam, fine-uri=uri-fine,
    scry-uri=uri-scry
::
/$  tools-to-json      %mcp-tools      %json
/$  prompts-to-json    %mcp-prompts    %json
/$  resources-to-json  %mcp-resources  %json
/$  templates-to-json  %mcp-templates  %json
::
|%
++  mcp-protocol-version  %'2025-11-25'
::
++  print-tang-to-wain
  |=  =tang
  ^-  wain
  %-  zing
  %+  turn
    tang
  |=  =tank
  %+  turn
    (wash [0 80] tank)
  |=  =tape
  (crip tape)
::
++  mark-mime
  |=  =mark
  ^-  @t
  ?+  mark  'application/octet-stream'
    %css   'text/css'
    %hoon  'text/hoon'
    %html  'text/html'
    %js    'text/javascript'
    %json  'application/json'
    %md    'text/markdown'
    %txt   'text/plain'
    %xml   'application/xml'
  ==
::
++  loopback-authority
  |=  authority=tape
  ^-  ?
  =/  suffix=(unit tape)
    ?:  =("localhost" (scag 9 authority))
      `(slag 9 authority)
    ?:  =("127.0.0.1" (scag 9 authority))
      `(slag 9 authority)
    ?:  =("[::1]" (scag 5 authority))
      `(slag 5 authority)
    ~
  ?~  suffix  %.n
  ?~  u.suffix  %.y
  ?.  =(':' i.u.suffix)  %.n
  ?=(^ (rush (crip t.u.suffix) dim:ag))
::
++  loopback-origin
  |=  origin=@t
  ^-  ?
  =/  origin-tape=tape  (trip origin)
  ?:  =("http://" (scag 7 origin-tape))
    (loopback-authority (slag 7 origin-tape))
  ?:  =("https://" (scag 8 origin-tape))
    (loopback-authority (slag 8 origin-tape))
  %.n
::
++  page-to-mime
  |=  [our=@p desk=@tas now=@da =page]
  ^-  mime
  ?:  =(%mime p.page)
    ;;(mime q.page)
  =/  =dais:clay
    .^(dais:clay %cb /(scot %p our)/[desk]/(scot %da now)/[p.page])
  =/  vax=vase  (vale:dais q.page)
  =/  =tube:clay
    .^(tube:clay %cc /(scot %p our)/[desk]/(scot %da now)/[p.page]/mime)
  !<(mime (tube vax))
::
++  fine-result
  |=  [our=@p desk=@tas now=@da rpc-id=@ta uri=@t =page]
  ^-  json
  =/  mime-result
    %-  mule
    |.
    (page-to-mime our desk now page)
  ?-  -.mime-result
  ::
      %|
    %-  internal:error:rpc
    :+  rpc-id
        (crip "Could not convert fine resource mark %{<p.page>} to %mime; ensure this desk has /mar/%{<p.page>}/hoon with +mime:grow arm")
    %-  some
    %-  pairs:enjs:format
    :~  ['uri' s+uri]
        ['mark' s+(crip (trip p.page))]
    ==
  ::
      %&
  =/  =mime  p.mime-result
  %-  result:rpc
  :-  rpc-id
  %-  pairs:enjs:format
  :~  :-  'contents'
      :-  %a
      :~  %-  pairs:enjs:format
          :~  ['uri' s+uri]
              ['mimeType' s+(rsh 3^1 (spat p.mime))]
              :-  'blob'
              :-  %s
              %-  en:base64:mimes:html
              q.mime
          ==
      ==
  ==
  ==
::
++  simple-response
  |=  [eyre-id=@ta status=@ud headers=(list [key=@t value=@t])]
  ^-  (list card)
  %+  give-simple-payload:app:server
    eyre-id
  ^-  simple-payload:http
  [[status headers] ~]
::
++  send-event
  |=  [eyre-id=@ta =json]
  ^-  (list card)
  %+  give-simple-payload:app:server
    eyre-id
  ^-  simple-payload:http
  :-  :-  200
      :~  ['content-type' 'application/json']
          ['cache-control' 'no-cache']
          ['MCP-Protocol-Version' mcp-protocol-version]
      ==
    %-  some
    %-  as-octt:mimes:html
    (trip (en:json:html json))
::
++  sse-data
  |=  =json
  ^-  octs
  %-  as-octt:mimes:html
  (trip (cat 3 'data: ' (cat 3 (en:json:html json) '\0a\0a')))
::
++  send-sse-start
  |=  eyre-id=@ta
  ^-  (list card)
  =/  response-header=response-header:http
    :-  200
    :~  ['content-type' 'text/event-stream']
        ['cache-control' 'no-cache']
        ['connection' 'keep-alive']
        ['MCP-Protocol-Version' mcp-protocol-version]
    ==
  :~  :*  %give  %fact  ~[/http-response/[eyre-id]]
          [%http-response-header !>(response-header)]
      ==
      :*  %give  %fact  ~[/http-response/[eyre-id]]
          [%http-response-data !>(`(as-octt:mimes:html ":\0a\0a"))]
      ==
  ==
::
++  send-sse-json
  |=  [eyre-id=@ta =json]
  ^-  (list card)
  :~  :*  %give  %fact  ~[/http-response/[eyre-id]]
          [%http-response-data !>(`(sse-data json))]
      ==
  ==
::
::  +send-sse-ping: SSE comment line to keep the connection open
::
++  send-sse-ping
  |=  eyre-id=@ta
  ^-  (list card)
  :~  :*  %give  %fact  ~[/http-response/[eyre-id]]
          [%http-response-data !>(`(as-octt:mimes:html ":\0a\0a"))]
      ==
  ==
::
++  close-sse
  |=  eyre-id=@ta
  ^-  (list card)
  ~[[%give %kick ~[/http-response/[eyre-id]] ~]]
::
++  keepalive-interval  ~s20
::
++  set-keepalive
  |=  [now=@da eyre-id=@ta]
  ^-  card
  [%pass /keepalive/[eyre-id] %arvo %b %wait (add now keepalive-interval)]
::
++  list-changed-notification
  |=  method=@t
  ^-  json
  %-  pairs:enjs:format
  :~  ['jsonrpc' s+'2.0']
      ['method' s+method]
  ==
::
++  broadcast-list-changed
  |=  [=bowl:gall sse-sessions=(map @ta session:mcp) method=@t]
  ^-  (list card:agent:gall)
  =/  notification=json  (list-changed-notification method)
  %-  zing
  %+  murn
    ~(tap by sse-sessions)
  |=  [eyre-id=@ta session:mcp]
  ^-  (unit (list card:agent:gall))
  =/  live=?
    %+  lien
      ~(tap by sup.bowl)
    |=  [=duct =ship pat=path]
    =(pat /http-response/[eyre-id])
  ?.  live
    ~
  `(send-sse-json eyre-id notification)
::
::  +json-response: respond with status code and JSON body
::    Used for endpoints that must return JSON (e.g. OAuth discovery
::    stubs at /.well-known/*) so MCP clients that probe per spec do
::    not choke trying to parse Eyre's HTML fallback as JSON.
::
++  json-response
  |=  [eyre-id=@ta status=@ud =json]
  ^-  (list card)
  %+  give-simple-payload:app:server
    eyre-id
  ^-  simple-payload:http
  :-  :-  status
      :~  ['content-type' 'application/json']
          ['cache-control' 'no-cache']
          ['MCP-Protocol-Version' mcp-protocol-version]
      ==
    %-  some
    %-  as-octt:mimes:html
    (trip (en:json:html json))
::
+$  card  card:agent:gall
::
::  +feature-files: every file under /fil/mcp at the current revision
::
++  feature-files
  |=  =bowl:gall
  ^-  (list path)
  .^  (list path)
      %ct
      /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)/fil/mcp
  ==
::
::  +install-features-card: fire /ted/install-features over every file
::  under /fil/mcp, registering tools, prompts, resources, and templates.
::  Imports replace entries by name, so re-firing this card is idempotent;
::  entries added at runtime under other names are untouched.
::
++  install-features-card
  |=  =bowl:gall
  ^-  card
  :*  %pass  ~
      %arvo  %k
      %fard  q.byk.bowl
      %install-features
      :-  %noun
      !>  ^-  (list beam)
      %+  turn
        (feature-files bowl)
      |=  pax=path
      ^-  beam
      %-  need
      %-  de-beam
      %+  welp
        /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)
      pax
  ==
::
::  +load-changed-cards: per-class list_changed notifications for the
::  features a desk update will register.  A feature's name lives inside
::  its file, not in the filename, and resolving it would mean building
::  every file during +on-load, so this compares a coarse proxy: the
::  number of files under /fil/mcp/<class> against the number of
::  features the class held before the load.  A no-op reload leaves the
::  counts equal (no notification); a new file makes them differ (one
::  notification for its class).  Features added at runtime skew the
::  count, at worst causing a spurious or missed notification here;
::  clients treat list_changed as a hint to re-fetch, and the %add-*
::  pokes the install-features thread sends still notify per change.
::
++  load-changed-cards
  |=  [=bowl:gall old=state-0]
  ^-  (list card)
  =/  files  (feature-files bowl)
  =/  count-under
    |=  prefix=path
    ^-  @ud
    %-  lent
    %+  skim  files
    |=  pax=path
    =(prefix (scag (lent prefix) pax))
  %-  zing
  ^-  (list (list card))
  :~  ?:  =((count-under /fil/mcp/tools) ~(wyt in tools.old))
        ~
      %:  broadcast-list-changed
          bowl
          sse-sessions.old
          'notifications/tools/list_changed'
      ==
    ::
      ?:  =((count-under /fil/mcp/prompts) ~(wyt in prompts.old))
        ~
      %:  broadcast-list-changed
          bowl
          sse-sessions.old
          'notifications/prompts/list_changed'
      ==
    ::
      ?:  ?&  =((count-under /fil/mcp/resources) ~(wyt in resources.old))
              =((count-under /fil/mcp/templates) ~(wyt in templates.old))
          ==
        ~
      %:  broadcast-list-changed
          bowl
          sse-sessions.old
          'notifications/resources/list_changed'
      ==
  ==
+$  versioned-state
  $%  state-0
  ==
+$  state-0
  $:  %0
      tools=(set tool:mcp)
      prompts=(set prompt:mcp)
      resources=(set resource:mcp)
      templates=(set template:resource:mcp)
      ::  map eyre-id to session:mcp
      sse-sessions=(map @ta session:mcp)
  ==
--
%-  agent:dbug
^-  agent:gall
=|  state-0
=*  state  -
%+  verb  |
|_  =bowl:gall
+*  this   .
    def    ~(. (default-agent this %|) bowl)
::
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  =/  oauth-card=card
    :*  %pass  /eyre/connect/oauth
        %arvo  %e  %connect
        [[~ ~['oauth']] dap.bowl]
    ==
  =/  well-known-card=card
    :*  %pass  /eyre/connect/well-known
        %arvo  %e  %connect
        [[~ ~['.well-known']] dap.bowl]
    ==
  ?-    -.old
      %0
    :_  this(state [%0 +.old])
    ::  Re-run install-features on every load so tool, prompt, resource,
    ::  and template files brought in by a desk update register without a
    ::  manual %fard (re-firing is idempotent: imports replace by name),
    ::  and tell connected clients which feature lists will change.
    ::
    %+  weld
      ^-  (list card)
      :~  oauth-card
          well-known-card
          (install-features-card bowl)
      ==
    (load-changed-cards bowl old)
  ==
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  :*  %pass  /eyre/connect
          %arvo  %e  %connect
          [`/mcp dap.bowl]
      ==
      ::  Bind /.well-known so we can stub OAuth discovery endpoints.
      ::  MCP clients probe these per the draft auth spec; without a
      ::  binding Eyre redirects to /apps/landscape/ (HTML), and the
      ::  client errors trying to parse HTML as JSON.
      ::
      :*  %pass  /eyre/connect/well-known
          %arvo  %e  %connect
          [[~ ~['.well-known']] dap.bowl]
      ==
      ::  Bind /oauth so DCR/authorize/token probes from MCP clients
      ::  get a clean RFC 6749 JSON error rather than Eyre's HTML
      ::  login fallback. Without this the Claude Code /mcp dialog's
      ::  OAuth flow disconnects the session even when cookie auth
      ::  is configured.
      ::
      :*  %pass  /eyre/connect/oauth
          %arvo  %e  %connect
          [[~ ~['oauth']] dap.bowl]
      ==
      (install-features-card bowl)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^  ?+  mark
        (on-poke:def mark vase)
      ::
          %handle-http-request
        (handle-req !<([@ta inbound-request:eyre] vase))
      ::
          ?(%import-tools %import-prompts %import-resources %import-templates)
        ?>  =(src our):bowl
        =/  desk=@t  !<(@t vase)
        =/  notif=@t
          ?-  mark
            %import-tools      'notifications/tools/list_changed'
            %import-prompts    'notifications/prompts/list_changed'
            %import-resources  'notifications/resources/list_changed'
            %import-templates  'notifications/resources/list_changed'
          ==
        :-  (broadcast-list-changed bowl sse-sessions notif)
        ?-    mark
            %import-tools
          =/  imported=(list tool:mcp)
            .^  (list tool:mcp)
                %gx
                /(scot %p our.bowl)/[desk]/(scot %da now.bowl)/mcp/tools/noun
            ==
          %=  this
            tools   %-  silt
                    %+  weld
                      imported
                    %+  murn
                      ~(tap in tools)
                    |=  old=tool:mcp
                    ^-  (unit tool:mcp)
                    ?:  %+  lien
                          imported
                        |=  new=tool:mcp
                        =(name.new name.old)
                      ~
                    `old
          ==
        ::
            %import-prompts
          =/  imported=(list prompt:mcp)
            .^  (list prompt:mcp)
                %gx
                /(scot %p our.bowl)/[desk]/(scot %da now.bowl)/mcp/prompts/noun
            ==
          %=  this
            prompts  %-  silt
                     %+  weld
                       imported
                     %+  murn
                       ~(tap in prompts)
                     |=  old=prompt:mcp
                     ^-  (unit prompt:mcp)
                     ?:  %+  lien
                           imported
                         |=  new=prompt:mcp
                         =(name.new name.old)
                         ~
                       `old
          ==
        ::
            %import-templates
          =/  imported=(list template:resource:mcp)
            .^  (list template:resource:mcp)
                %gx
                /(scot %p our.bowl)/[desk]/(scot %da now.bowl)/mcp/templates/noun
            ==
          %=  this
            templates  %-  silt
                       %+  weld
                         imported
                       %+  murn
                         ~(tap in templates)
                       |=  old=template:resource:mcp
                       ^-  (unit template:resource:mcp)
                       ?:  %+  lien
                             imported
                           |=  new=template:resource:mcp
                           =(name.new name.old)
                         ~
                       `old
          ==
        ::
            %import-resources
          =/  imported=(list resource:mcp)
            .^  (list resource:mcp)
                %gx
                /(scot %p our.bowl)/[desk]/(scot %da now.bowl)/mcp/resources/noun
            ==
          %=  this
            resources  %-  silt
                       %+  weld
                         imported
                       %+  murn
                         ~(tap in resources)
                       |=  old=resource:mcp
                       ^-  (unit resource:mcp)
                       ?:  %+  lien
                             imported
                           |=  new=resource:mcp
                           =(uri.new uri.old)
                         ~
                       `old
          ==
        ==
      ::
          ?(%add-tool %add-prompt %add-resource %add-template)
        ?>  =(src our):bowl
        =/  notif=@t
          ?-  mark
            %add-tool      'notifications/tools/list_changed'
            %add-prompt    'notifications/prompts/list_changed'
            %add-resource  'notifications/resources/list_changed'
            %add-template  'notifications/resources/list_changed'
          ==
        ::  An add that leaves the feature set as it was (for instance
        ::  the install-features thread re-importing an unchanged file
        ::  on load) is not a list change; skip the broadcast for it.
        ::
        =/  changed=?
          ?-  mark
            %add-tool      !(~(has in tools) !<(tool:mcp vase))
            %add-prompt    !(~(has in prompts) !<(prompt:mcp vase))
            %add-resource  !(~(has in resources) !<(resource:mcp vase))
            %add-template  !(~(has in templates) !<(template:resource:mcp vase))
          ==
        :-  ?.  changed
              ~
            (broadcast-list-changed bowl sse-sessions notif)
        ?-  mark
          %add-tool
            =/  new=tool:mcp  !<(tool:mcp vase)
            %=  this
              tools   %-  silt
                      :-  new
                      %+  murn
                        ~(tap in tools)
                      |=  old=tool:mcp
                      ^-  (unit tool:mcp)
                      ?:  =(name.new name.old)
                        ~
                      `old
            ==
          %add-prompt
            =/  new=prompt:mcp  !<(prompt:mcp vase)
            %=  this
              prompts  %-  silt
                       :-  new
                       %+  murn
                         ~(tap in prompts)
                       |=  old=prompt:mcp
                       ^-  (unit prompt:mcp)
                       ?:  =(name.new name.old)
                         ~
                       `old
            ==
          %add-resource
            =/  new=resource:mcp  !<(resource:mcp vase)
            %=  this
              resources  %-  silt
                         :-  new
                         %+  murn
                           ~(tap in resources)
                         |=  old=resource:mcp
                         ^-  (unit resource:mcp)
                         ?:  =(uri.new uri.old)
                           ~
                           `old
            ==
          %add-template
            =/  new=template:resource:mcp  !<(template:resource:mcp vase)
            %=  this
              templates  %-  silt
                         :-  new
                         %+  murn
                           ~(tap in templates)
                         |=  old=template:resource:mcp
                         ^-  (unit template:resource:mcp)
                         ?:  =(name.new name.old)
                           ~
                           `old
            ==
        ==
      ==
  ++  handle-req
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    ::  OAuth discovery probes from MCP clients land here via the
    ::  /.well-known binding. We don't speak OAuth; auth is by
    ::  Cookie or session header per Eyre. Return RFC 9728 protected-
    ::  resource metadata with no authorization servers, signalling
    ::  to the client that it should proceed with the auth scheme
    ::  it already has (rather than triggering an OAuth handshake
    ::  that ends in Eyre's HTML login fallback).
    ::
    =/  url-tape=tape  (trip url.request.req)
    =/  host=@t
      =/  h=(unit @t)
        (get-header:http 'host' header-list.request.req)
      ?~(h 'localhost' u.h)
    ::
    ::  Reject browser origins that do not correspond to the local
    ::  endpoint or our EAuth URL.
    =/  local=?  (loopback-authority (trip host))
    =/  origin=(unit @t)
      (get-header:http 'origin' header-list.request.req)
    =/  origin-allowed=?
      ?~  origin
        .y
      ?:  local
        (loopback-origin u.origin)
      =/  eauth=(unit @t)
        .^  (unit @t)
            %ex
            /(scot %p our.bowl)//(scot %da now.bowl)/eauth/url
        ==
      ?~  eauth
        .n
      =(u.origin u.eauth)
    ?.  origin-allowed
      [(simple-response eyre-id 403 ~) this]
    =/  base=@t  (rap 3 'http://' host ~)
    ::  RFC 9728 protected-resource metadata at the spec'd path.
    ::  Empty authorization_servers + bearer_methods=header tells
    ::  the client to use the auth header it already has.
    ::
    ?:  =("/.well-known/oauth-protected-resource" url-tape)
      =/  meta=json
        %-  pairs:enjs:format
        :~  ['resource' s+(cat 3 base '/mcp')]
            ['authorization_servers' a+~]
            ['bearer_methods_supported' a+~[s+'header']]
        ==
      :_  this
      (json-response eyre-id 200 meta)
    ::  RFC 8414 authorization-server metadata. We don't actually
    ::  speak OAuth, but a Zod-valid stub keeps the client out of
    ::  parse-error territory; the OAuth flow itself fails cleanly
    ::  at the /oauth/* endpoints below.
    ::
    ?:  =("/.well-known/oauth-authorization-server" url-tape)
      =/  meta=json
        %-  pairs:enjs:format
        :~  ['issuer' s+base]
            ['authorization_endpoint' s+(cat 3 base '/oauth/authorize')]
            ['token_endpoint' s+(cat 3 base '/oauth/token')]
            ['registration_endpoint' s+(cat 3 base '/oauth/register')]
            ['response_types_supported' a+~[s+'code']]
            ['grant_types_supported' a+~[s+'authorization_code']]
            ['code_challenge_methods_supported' a+~[s+'S256']]
            ['token_endpoint_auth_methods_supported' a+~[s+'none']]
        ==
      :_  this
      (json-response eyre-id 200 meta)
    ::  Any other /.well-known/* probe gets a JSON 404.
    ::
    ?:  ?&  (gte (lent url-tape) 12)
            =("/.well-known" (scag 12 url-tape))
        ==
      :_  this
      (json-response eyre-id 404 (pairs:enjs:format ~[['error' s+'not found']]))
    ::  OAuth endpoint stubs. We don't speak OAuth; auth is via the
    ::  Cookie/header configured on the MCP client. Returning a
    ::  proper RFC 6749 JSON error keeps clients (e.g. Claude Code's
    ::  /mcp dialog) from choking on Eyre's HTML login fallback.
    ::
    ?:  ?&  (gte (lent url-tape) 6)
            =("/oauth" (scag 6 url-tape))
        ==
      =/  err=json
        %-  pairs:enjs:format
        :~  ['error' s+'unsupported_response_type']
            ['error_description' s+'this server does not implement OAuth']
        ==
      :_  this
      (json-response eyre-id 400 err)
    ?.  authenticated.req
      :_  this
      (send-event eyre-id (internal:error:rpc '0' 'Authentication required' ~))
    ?+  method.request.req
      [(simple-response eyre-id 405 ~[['allow' 'GET, POST']]) this]
    ::
        %'GET'
      =/  accept=(unit @t)
        (get-header:http 'accept' header-list.request.req)
      ?~  accept
        [(simple-response eyre-id 406 ~) this]
      ?.  ?=(^ (find "text/event-stream" (trip u.accept)))
        [(simple-response eyre-id 406 ~) this]
      =/  session-id=@t
        ?~  get-session=(get-header:http 'mcp-session-id' header-list.request.req)
          eyre-id
        u.get-session
      :_  this(sse-sessions (~(put by sse-sessions) eyre-id session-id))
      (send-sse-start eyre-id)
    ::
        %'DELETE'
      [(simple-response eyre-id 405 ~[['allow' 'GET, POST']]) this]
    ::
        %'POST'
      =/  client-protocol-version=(unit @t)
        (get-header:http 'mcp-protocol-version' header-list.request.req)
      =/  bad-protocol-version=?
        ?~  client-protocol-version
          .n
        !=(u.client-protocol-version mcp-protocol-version)
      ?:  bad-protocol-version
        :_  this
        %:  json-response
            eyre-id
            400
            (pairs:enjs:format ~[['error' s+'Unsupported MCP-Protocol-Version']])
        ==
      =/  accept=(unit @t)
        (get-header:http 'accept' header-list.request.req)
      ?~  accept
        :_  this
        %:  json-response
            eyre-id
            400
            (pairs:enjs:format ~[['error' s+'Missing Accept header']])
        ==
      ?.  ?=(^ (find "application/json" (trip u.accept)))
        :_  this
        %:  json-response
            eyre-id
            406
            (pairs:enjs:format ~[['error' s+'Accept must include application/json']])
        ==
      =/  content-type=(unit @t)
        (get-header:http 'content-type' header-list.request.req)
      ?+  content-type
        [(simple-response eyre-id 415 ~[['MCP-Protocol-Version' mcp-protocol-version]]) this]
      ::
          ?([~ %'application/json'] [~ %'application/json; charset=utf-8'])
        =/  parsed=(unit json)
          (de:json:html q:(need body.request.req))
        ?~  parsed
          [(simple-response eyre-id 400 ~) this]
        %.  u.parsed
        |=  jon=json
        =/  method=(unit json)  (~(get jo:jut jon) /method)
        ?:  =([~ [%s %'notifications/initialized']] method)
          [(simple-response eyre-id 202 ~[['MCP-Protocol-Version' mcp-protocol-version]]) this]
        =/  id=(unit json)      (~(get jo:jut jon) /id)
        ?>  ?=(^ id)
        ?>  ?=([%n p=@ta] u.id)
        ?+  method
          :_  this
          (send-event eyre-id (method:error:rpc p.u.id 'Method not found' ~))
        ::
            [~ [%s %'notifications/initialized']]
          [(simple-response eyre-id 202 ~[['MCP-Protocol-Version' mcp-protocol-version]]) this]
        ::
            [~ [%s %'initialize']]
          ::  XX check protocol version?
          ::     would mean we have to declare compat
          :_  this
          %:  send-event
              eyre-id
              %-  pairs:enjs:format
              :~  ['id' n+p.u.id]
                  ['jsonrpc' s+'2.0']
                  :-  'result'
                  %-  pairs:enjs:format
                      :~  ['protocolVersion' s+mcp-protocol-version]
                      :-  'capabilities'
                      %-  pairs:enjs:format
                      :~  :-  'tools'
                          (pairs:enjs:format ~[['listChanged' b+%.y]])
                          :-  'prompts'
                          (pairs:enjs:format ~[['listChanged' b+%.y]])
                          :-  'resources'
                          %-  pairs:enjs:format
                          :~  ['subscribe' b+%.n]
                              ['listChanged' b+%.y]
                          ==
                      ==
                      :-  'serverInfo'
                      %-  pairs:enjs:format
                      ::  XX specify real or fake in the server name
                      :~  ['name' s+(crip "{<our.bowl>} urbit mcp server")]
                          ['version' s+'1.0.0']
          ==  ==  ==  ==
        ::
            [~ [%s %'tools/list']]
          :_  this
          (send-event eyre-id (result:rpc p.u.id (tools-to-json ~(tap in tools))))
        ::
            [~ [%s %'resources/list']]
          :_  this
          (send-event eyre-id (result:rpc p.u.id (resources-to-json ~(tap in resources))))
        ::
            [~ [%s %'resources/templates/list']]
          :_  this
          (send-event eyre-id (result:rpc p.u.id (templates-to-json ~(tap in templates))))
        ::
            [~ [%s %'prompts/list']]
          :_  this
          (send-event eyre-id (result:rpc p.u.id (prompts-to-json ~(tap in prompts))))
        ::
            [~ [%s %'resources/read']]
         =/  request-id=(unit @ud)
           (bind id ni:dejs:format)
         ?~  request-id
           :_  this
           (send-event eyre-id (params:error:rpc p.u.id 'Missing or invalid JSON RPC request ID' ~))
          =/  uri=(unit @t)
            (~(deg jo:jut jon) /params/uri so:dejs:format)
          ?~  uri
            :_  this
            (send-event eyre-id (params:error:rpc p.u.id 'Missing or invalid resource URI' ~))
          =/  scheme=cord
            %-  crip
            %-  head
            %.  (trip u.uri)
            |=  =tape
            ^-  (list ^tape)
            =|  res=(list ^tape)
            |-
            ?~  tape
              (flop res)
            =/  off  (find "://" tape)
            ?~  off
              (flop [`^tape`tape `(list ^tape)`res])
            %=  $
              res   [(scag `@ud`(need off) `^tape`tape) res]
              tape  (slag +(`@ud`(need off)) `^tape`tape)
            ==
          ?+  scheme
            :_  this
            %:  send-event
                eyre-id
                %:  request:error:rpc
                    p.u.id
                    'Scheme not supported for URI'
                    `(frond:enjs:format %uri s+u.uri)
            ==  ==
          ::
              %'beam'
            =/  parsed-beam=(unit beam)
              (parse:beam-uri byk.bowl u.uri)
            ?~  parsed-beam
              :_  this
              %:  send-event
                  eyre-id
                  %:  request:error:rpc
                      p.u.id
                      'Invalid beam'
                      `(frond:enjs:format %uri s+u.uri)
              ==  ==
            :_  this
            :~  :*  %pass
                    /response/resource/beam/[eyre-id]/(scot %ud u.request-id)/[u.uri]
                    %arvo
                    %c
                    %warp
                    :*  p.u.parsed-beam
                        q.u.parsed-beam
                        ~
                        %sing  %x
                        r.u.parsed-beam
                        s.u.parsed-beam
                    ==
            ==  ==
          ::
              ?(%'http' %'https')
            =/  request-id=(unit @ud)
              (bind id ni:dejs:format)
            ?~  request-id
              :_  this
              (send-event eyre-id (params:error:rpc p.u.id 'Missing or invalid JSON RPC request ID' ~))
            :_  this
            :~  :*  %pass
                    /response/resource/http/[eyre-id]/(scot %ud u.request-id)/[u.uri]
                    %arvo
                    %i
                    [%request [%'GET' u.uri ~ ~] *outbound-config:iris]
            ==  ==
          ::
              %'scry'
            =/  parsed-scry-uri=(unit path)
              (parse:scry-uri u.uri)
            ?~  parsed-scry-uri
              :_  this
              %+  send-event
                eyre-id
              %:  request:error:rpc
                  p.u.id
                  'Invalid scry URI'
                  `(frond:enjs:format %uri s+u.uri)
              ==
            =/  care-segment=@t  (head u.parsed-scry-uri)
            =/  scry-path=path  (slag 1 u.parsed-scry-uri)
            =/  vane=@t  (cut 3 [0 1] care-segment)
            =/  care=@t  (cut 3 [1 1] care-segment)
            ?+    vane
                :_  this
                %+  send-event
                  eyre-id
                %:  params:error:rpc
                    p.u.id
                    'Unknown or unsupported vane'
                    `(frond:enjs:format %vane s+vane)
                ==
            ::
                %g
              ?+    care
                  :_  this
                  %+  send-event
                    eyre-id
                  %:  params:error:rpc
                      p.u.id
                      'Unsupported Gall scry care'
                      `(frond:enjs:format %care s+care)
                  ==
              ::
                  ?(%d %e %u)
                ?.  =(1 (lent scry-path))
                  :_  this
                  %+  send-event
                    eyre-id
                  %:  params:error:rpc
                      p.u.id
                      'Gall vane scry URI must contain exactly one agent or desk'
                      `(frond:enjs:format %uri s+u.uri)
                  ==
                =/  scry-result
                  %-  mule
                  |.
                    =/  gall-care
                      ?-  care
                        %d  %gd
                        %e  %ge
                        %u  %gu
                      ==
                    .^  *
                        gall-care
                        /(scot %p our.bowl)/[(head scry-path)]/(scot %da now.bowl)/$
                    ==
                ?>  ?=([? p=*] scry-result)
                ?.  -.scry-result
                  :_  this
                  (send-event eyre-id (internal:error:rpc p.u.id (crip (print-tang-to-wain (tang p.scry-result))) ~))
                =/  result-text=@t
                  ?-  care
                    %d
                  (en:json:html [%s (scot %tas ;;(desk p.scry-result))])
                    %e
                  =/  apps=(set [=dude:gall live=?])
                    ;;((set [=dude:gall live=?]) p.scry-result)
                  %-  en:json:html
                  :-  %a
                  %+  turn
                    ~(tap in apps)
                  |=  [=dude:gall live=?]
                  %-  pairs:enjs:format
                  :~  ['agent' s+(scot %tas dude)]
                      ['running' b+live]
                  ==
                    %u
                  ?:  ;;(? p.scry-result)
                    'true'
                  'false'
                  ==
                :_  this
                %:  send-event
                    eyre-id
                    %-  result:rpc
                    :-  p.u.id
                    %-  pairs:enjs:format
                    :~  :-  'contents'
                        :-  %a
                        :~  %-  pairs:enjs:format
                            :~  ['uri' s+u.uri]
                                ['mimeType' s+'application/json']
                                ['text' s+result-text]
                            ==
                        ==
                    ==
                ==
              ::
                  %x
                ?.  =(%json (rear scry-path))
                  :_  this
                  %+  send-event
                    eyre-id
                  %:  params:error:rpc
                      p.u.id
                      'Gall scry resource path must end in /json'
                      `(frond:enjs:format %uri s+u.uri)
                  ==
                =/  scry-result
                  %-  mule
                  |.
                    .^  *
                        %gx
                        %+  welp
                          /(scot %p our.bowl)/[(head scry-path)]/(scot %da now.bowl)
                        (slag 1 scry-path)
                    ==
                ?>  ?=([? p=*] scry-result)
                ?.  -.scry-result
                  :_  this
                  (send-event eyre-id (internal:error:rpc p.u.id (crip (print-tang-to-wain (tang p.scry-result))) ~))
                =/  scry-json=json  (json p.scry-result)
                :_  this
                %:  send-event
                    eyre-id
                    %-  result:rpc
                    :-  p.u.id
                    %-  pairs:enjs:format
                    :~  :-  'contents'
                        :-  %a
                        :~  %-  pairs:enjs:format
                            :~  ['uri' s+u.uri]
                                ['mimeType' s+'application/json']
                                ['text' s+(en:json:html scry-json)]
                            ==
                        ==
                    ==
                ==
              ==
            ::
                %c
              =/  clay-scry-path=path
                ?:  ?&  =(%w care)
                        =(1 (lent scry-path))
                    ==
                  (weld scry-path /[(scot %da now.bowl)])
                scry-path
              ?+    care
                  :_  this
                  %+  send-event
                    eyre-id
                  %:  params:error:rpc
                      p.u.id
                      'Unsupported Clay scry care'
                      `(frond:enjs:format %care s+care)
                  ==
              ::
                  %d
                ?.  =(0 (lent scry-path))
                  :_  this
                  %+  send-event
                    eyre-id
                  %:  params:error:rpc
                      p.u.id
                      'Clay list-desks scry URI must not contain a path'
                      `(frond:enjs:format %uri s+u.uri)
                  ==
                =/  scry-result
                  %-  mule
                  |.
                    .^  *
                        %cd
                        /(scot %p our.bowl)//(scot %da now.bowl)
                    ==
                ?>  ?=([? p=*] scry-result)
                ?.  -.scry-result
                  :_  this
                  (send-event eyre-id (internal:error:rpc p.u.id (crip (print-tang-to-wain (tang p.scry-result))) ~))
                =/  result-text=@t
                  %-  en:json:html
                  :-  %a
                  %+  turn
                    ~(tap in ;;((set desk) p.scry-result))
                  |=  =desk
                  [%s (scot %tas desk)]
                :_  this
                %:  send-event
                    eyre-id
                    %-  result:rpc
                    :-  p.u.id
                    %-  pairs:enjs:format
                    :~  :-  'contents'
                        :-  %a
                        :~  %-  pairs:enjs:format
                            :~  ['uri' s+u.uri]
                                ['mimeType' s+'application/json']
                                ['text' s+result-text]
                            ==
                        ==
                    ==
                ==
              ::
                  ?(%p %t %u %w %z)
                =/  parsed-beam=(unit beam)
                  (de-beam (welp /(scot %p our.bowl) clay-scry-path))
                ?~  parsed-beam
                  :_  this
                  %+  send-event
                    eyre-id
                  %:  request:error:rpc
                      p.u.id
                      'Invalid Clay scry path'
                      `(frond:enjs:format %uri s+u.uri)
                  ==
                =/  clay-care=care:clay
                  ?-  care
                    %p  %p
                    %t  %t
                    %u  %u
                    %w  %w
                    %z  %z
                  ==
                :_  this
                :~  :*  %pass
                        /response/resource/scry/clay/[care]/[eyre-id]/(scot %ud u.request-id)/[u.uri]
                        %arvo
                        %c
                        %warp
                        :*  p.u.parsed-beam
                            q.u.parsed-beam
                            ~
                            %sing  clay-care
                            r.u.parsed-beam
                            s.u.parsed-beam
                        ==
                ==  ==
              ::
                  %x
                =/  parsed-beam=(unit beam)
                  (de-beam (welp /(scot %p our.bowl) clay-scry-path))
                ?~  parsed-beam
                  :_  this
                  %+  send-event
                    eyre-id
                  %:  request:error:rpc
                      p.u.id
                      'Invalid Clay scry path'
                      `(frond:enjs:format %uri s+u.uri)
                  ==
                :_  this
                :~  :*  %pass
                        /response/resource/scry/clay/x/[eyre-id]/(scot %ud u.request-id)/[u.uri]
                        %arvo
                        %c
                        %warp
                        :*  p.u.parsed-beam
                            q.u.parsed-beam
                            ~
                            %sing  %x
                            r.u.parsed-beam
                            s.u.parsed-beam
                        ==
                ==  ==
              ==
            ==
          ::
              %'fine'
            ::  Try the public namespace first.  +parse:fine-uri normalizes
            ::  fine://.../g/x/revision/agent//1/path to the spar Ames expects.
            ::  A null result is retried as a two-party encrypted %chum
            ::  request in +on-arvo.
            =/  parsed-fine=(unit spar:ames)
              (parse:fine-uri u.uri)
            ?~  parsed-fine
              :_  this
              (send-event eyre-id (request:error:rpc p.u.id (crip "Invalid fine URI {<u.uri>}") ~))
            :_  this
            :~  :*  %pass
                    /response/resource/fine/keen/[eyre-id]/(scot %ud u.request-id)/[u.uri]
                    %arvo  %a  %keen  ~
                    u.parsed-fine
            ==  ==
          ==
        ::
            [~ [%s %'prompts/get']]
          =/  prompt-name=(unit @t)
            (~(deg jo:jut jon) /params/name so:dejs:format)
          ?~  prompt-name
            :_  this
            (send-event eyre-id (params:error:rpc p.u.id 'Missing or invalid prompt name' ~))
          =/  prompt-results
            %+  murn
              ~(tap in prompts)
            |=  =prompt:mcp
            ^-  (unit prompt:mcp)
            ?.  =(name.prompt u.prompt-name)
              ~
            `prompt
          ?~  prompt-results
            :_  this
            %+  send-event
              eyre-id
            %:  method:error:rpc
                p.u.id
                'Prompt not found'
                `(frond:enjs:format %name s+u.prompt-name)
            ==
          ?:  (gth 1 (lent prompt-results))
            :_  this
            %+  send-event
              eyre-id
            %:  internal:error:rpc
                p.u.id
                'Multiple prompts found'
                `(frond:enjs:format %name s+u.prompt-name)
            ==
          =/  =prompt:mcp  i.prompt-results
          =/  prompt-args=(map name:argument:prompt:mcp @t)
            %+  fall
              (~(deg jo:jut jon) /params/arguments (om so):dejs:format)
            *(map name:argument:prompt:mcp @t)
          :_  this
          %:  send-event
              eyre-id
              %-  result:rpc
              :-  p.u.id
              %-  pairs:enjs:format
              :~  ['description' s+desc.prompt]
                  :-  'messages'
                  %.  (messages-builder.prompt prompt-args)
                  |=  messages=(list message:prompt:mcp)
                  ^-  json
                  :-  %a
                  %+  turn
                    messages
                  |=  =message:prompt:mcp
                  ^-  json
                  %-  pairs:enjs:format
                  :~  ['role' s+role.message]
                      :-  'content'
                      %-  pairs:enjs:format
                      :~  ['type' s+type.content.message]
                          ?~  text.content.message
                            ['text' s+'']
                          ['text' s+u.text.content.message]
                      ==
                  ==
              ==
          ==
        ::
            [~ [%s %'tools/call']]
          =/  rpc-id=(unit @ud)  (bind id ni:dejs:format)
          ?~  rpc-id
            :_  this
            (send-event eyre-id (params:error:rpc p.u.id 'Missing JSON RPC request ID' ~))
          :_  this
          =/  tool-name=(unit @t)
            (~(deg jo:jut jon) /params/name so:dejs:format)
          ?~  tool-name
            (send-event eyre-id (params:error:rpc p.u.id 'Missing or invalid tool name' ~))
          =/  tool-results
            %+  murn
              ~(tap in tools)
            ::  XX placeholder name
            |=  foo=tool:mcp
            ^-  (unit tool:mcp)
            ?.  =(name.foo u.tool-name)
              ~
            `foo
          ?~  tool-results
            %+  send-event
              eyre-id
            %:  params:error:rpc
                p.u.id
                'Tool not found'
                `(frond:enjs:format %name s+u.tool-name)
            ==
          ?:  (gth 1 (lent tool-results))
            %+  send-event
              eyre-id
            %:  internal:error:rpc
                p.u.id
                'Multiple tools found'
                `(frond:enjs:format %name s+u.tool-name)
            ==
          =/  arguments=(unit json)  (~(get jo:jut jon) /params/arguments)
          ?~  arguments
            (send-event eyre-id (params:error:rpc p.u.id 'Missing arguments' ~))
          =/  args-map=(unit (map @t json))
            ?:  ?=([%o *] u.arguments)
              `p.u.arguments
            ~
          ?~  args-map
            (send-event eyre-id (params:error:rpc p.u.id 'Invalid arguments' ~))
          =>  |%
              ++  parse-arg
                |=  jon=json
                ^-  argument:tool:mcp
                ?+  jon
                  ~
                ::
                    [%a *]
                  [%array (turn p.jon parse-arg)]
                ::
                    [%b ?]
                  [%boolean p.jon]
                ::
                    [%o *]
                  [%object (~(run by p.jon) parse-arg)]
                ::
                    [%n @ta]
                  [%number (slav %ud p.jon)]
                ::
                    [%s @t]
                  [%string p.jon]
                ==
              --
          ^-  (list card)
          ::  When the client accepts SSE (the MCP streamable-HTTP spec
          ::  says it must for POST), answer with an SSE stream and ping
          ::  it on a timer so long-running tools don't lose the
          ::  connection before the thread finishes.
          ::
          =/  sse=?  ?=(^ (find "text/event-stream" (trip u.accept)))
          =/  mode=@ta  ?:(sse %sse %plain)
          =/  run-tool=card
            :*  %pass  /response/tool/[eyre-id]/(scot %ud u.rpc-id)/[mode]
                %arvo  %k
                %lard  q.byk.bowl
                %-  thread-builder.i.tool-results
                (~(run by u.args-map) parse-arg)
            ==
          ?.  sse
            ~[run-tool]
          %+  weld
            (send-sse-start eyre-id)
          ~[(set-keepalive now.bowl eyre-id) run-tool]
        ==
      ==
    ==
  --
++  on-peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+  pole  (on-peek:def `path`pole)
    ::
    ::  .^(json %gx /=mcp-server=/mcp/tools/json)
    ::  .^((list tool:mcp) %gx /=mcp-server=/mcp/tools/noun)
    ::  read tool definitions
      [%x %mcp %tools ~]
    ``mcp-tools+!>(~(tap in tools))
    ::
    ::  .^(json %gx /=mcp-server=/mcp/prompts/json)
    ::  .^((list prompt:mcp) %gx /=mcp-server=/mcp/prompts/noun)
    ::  read prompt definitions
      [%x %mcp %prompts ~]
    ``mcp-prompts+!>(~(tap in prompts))
    ::
    ::  .^(json %gx /=mcp-server=/mcp/resources/json)
    ::  .^((list resource:mcp) %gx /=mcp-server=/mcp/resource/noun)
    ::  read resource definitions
      [%x %mcp %resources ~]
    ``mcp-resources+!>(~(tap in resources))
    ::
    ::  .^(json %gx /=mcp-server=/mcp/templates/json)
    ::  .^((list template:resource:mcp) %gx /=mcp-server=/mcp/templates/noun)
    ::  read resource template definitions
      [%x %mcp %templates ~]
    ``mcp-templates+!>(~(tap in templates))
    ::
    ::  search for tools under a path (e.g. /urbit, /urbit/mcp)
    ::  .^(json %gx /=mcp-server=/mcp/tools/urbit/mcp/json)
    ::  .^((list tool:mcp) %gx /=mcp-server=/mcp/tools/urbit/mcp/noun)
      [%x %mcp %tools pax=*]
    =/  =path  pax.pole
    %-  some
    %-  some
    :-  %mcp-tools
    !>  ^-  (list tool:mcp)
    %+  murn
      ~(tap in tools)
    |=  =tool:mcp
    ^-  (unit tool:mcp)
    ?.  =(path (scag (lent path) (stab (rap 3 '/' name.tool ~))))
      ~
    `tool
  ==
++  on-arvo
  |=  [=(pole knot) =sign-arvo]
  ^-  (quip card _this)
  ?+  pole
    `this
  ::
      [%keepalive eyre-id=@ta ~]
    ?>  ?=([%behn %wake *] sign-arvo)
    ::  Ping only while the response channel is still open; once the
    ::  result is sent (or the client leaves) the subscription is gone
    ::  and the timer chain stops.
    ::
    =/  live=?
      %+  lien
        ~(tap by sup.bowl)
      |=  [=duct =ship pat=path]
      =(pat /http-response/[eyre-id.pole])
    ?.  live
      `this
    :_  this
    :-  (set-keepalive now.bowl eyre-id.pole)
    (send-sse-ping eyre-id.pole)
  ::
      [%eyre %connect ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ?:  accepted.sign-arvo
      `this
    %-  (slog leaf/"mcp: failed to bind {<dap.bowl>} to /mcp" ~)
    `this
  ::
      [%response %tool eyre-id=@ta rpc-id=@ta mode=@ta ~]
    ::  +finish: deliver the tool result. Over SSE, send the JSON as an
    ::  event and close the stream; otherwise, one plain HTTP response.
    ::
    =/  finish
      |=  =json
      ^-  (list card)
      ?.  =(%sse mode.pole)
        (send-event eyre-id.pole json)
      %+  weld
        (send-sse-json eyre-id.pole json)
      (close-sse eyre-id.pole)
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%khan %arow *]
      ?:  ?=(%.n -.p.sign-arvo)
        :_  this
        %-  finish
        (internal:error:rpc rpc-id.pole (crip (print-tang-to-wain tang.p.p.sign-arvo)) ~)
      ?>  ?=([%khan %arow %.y %noun *] sign-arvo)
      =/  [%khan %arow %.y %noun =vase]  sign-arvo
      =/  =response:tool:mcp  !<(response:tool:mcp vase)
        :_  this
        %-  finish
        ?-    -.response
            %error
          %-  pairs:enjs:format
          :~  ['id' n+rpc-id.pole]
              ['jsonrpc' s+'2.0']
              :-  'result'
              %-  pairs:enjs:format
              %-  zing
              :~  :~  :-  'content'
                      :-  %a
                      :~  %-  pairs:enjs:format
                          :~  ['type' s+'text']
                              ['text' s+message.response]
                          ==
                      ==
                  ==
                  ?~  data.response
                    ~
                  :~  ['structuredContent' u.data.response]
                  ==
                  :~  ['isError' b+.y]
                  ==
              ==
          ==
        ::
            %result
          %-  pairs:enjs:format
          :~  ['id' n+rpc-id.pole]
              ['jsonrpc' s+'2.0']
              :-  'result'
              ?-    response
                  [%result %structured *]
                ::  structuredContent must be a JSON object or
                ::  some clients will fail silently
                ?.  ?=(%o -.json.response)
                  %-  pairs:enjs:format
                  :~  ['isError' b+.y]
                      :-  'content'
                      :-  %a
                      :~  %-  pairs:enjs:format
                          :~  ['type' s+'text']
                              :-  'text'
                              :-  %s
                              %-  en:json:html
                              %-  frond:enjs:format
                              :-  'error'
                              :-  %s
                              'structuredContent output is not a valid JSON object'
                          ==
                      ==
                  ==
                %-  pairs:enjs:format
                :~  :-  'content'
                    :-  %a
                    :~  %-  pairs:enjs:format
                        :~  ['type' s+'text']
                            ['text' s+(en:json:html json.response)]
                        ==
                    ==
                    ['structuredContent' json.response]
                    ['isError' b+.n]
                ==
              ::
                  [%result %unstructured *]
                %-  frond:enjs:format
                :-  'content'
                :-  %a
                %+  turn
                  results.response
                |=  =result:tool:mcp
                ^-  json
                ?-    -.result
                    %text
                  %-  pairs:enjs:format
                  :~  ['type' s+'text']
                      ['text' s+text.result]
                  ==
                ::
                    %audio
                  %-  pairs:enjs:format
                  :~  ['type' s+'audio']
                      ['data' s+data.result]
                      ['mimeType' s+mime.result]
                  ==
                ::
                    %resource-link
                  %-  pairs:enjs:format
                  :~  ['type' s+'resource_link']
                      ['uri' s+uri.result]
                      ['name' s+name.result]
                      ['description' s+desc.result]
                      ['mimeType' s+mime.result]
                  ==
                ::
                    %image
                  %-  pairs:enjs:format
                  ::  XX parse annotations
                  :~  ['type' s+'image']
                      ['data' s+data.result]
                      ['mimeType' s+mime.result]
                  ==
                ::
                    %resource
                  ::  XX parse annotations
                  %-  pairs:enjs:format
                  :~  ['type' s+'resource']
                      :-  'resource'
                      %-  pairs:enjs:format
                      :~  ['uri' s+uri.result]
                          ['mimeType' s+mime.result]
                          ['text' s+text.result]
                      ==
                  ==
                ==
              ==
          ==
        ==
      ==
  ::
      [%response %resource %beam eyre-id=@ta rpc-id=@ta uri=@t ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
      ::
        [%clay %writ *]
      =/  [%clay %writ =riot:clay]  sign-arvo
      :_  this
      %:  send-event
          eyre-id.pole
          %-  result:rpc
          :-  rpc-id.pole
          %-  pairs:enjs:format
          :~  :-  'contents'
              :-  %a
              :~  %-  pairs:enjs:format
                  %+  welp
                    :~  ['uri' s+uri.pole]
                        :-  'text'
                        :-  %s
                        ?~  riot
                          'Failed to fetch file.'
                        %-  crip
                        %-  print-tang-to-wain
                        %-  pretty-file:pf
                        !<(noun q.r.u.riot)
                    ==
                  ?~  riot
                    ~
                  :~  ['mimeType' s+(mark-mime p.r.u.riot)]
                  ==
              ==
          ==
      ==
    ==
  ::
      [%response %resource %scry %clay care=@tas eyre-id=@ta rpc-id=@ta uri=@t ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%clay %writ *]
      =/  [%clay %writ =riot:clay]  sign-arvo
      =/  result-text=@t
        ?~  riot
          'Failed to perform Clay scry.'
        ?+  care.pole  'Unsupported Clay scry care.'
          %x
            %-  crip
            %-  print-tang-to-wain
            %-  pretty-file:pf
            !<(noun q.r.u.riot)
          %p
            =/  permissions=[read=dict:clay write=dict:clay]
              !<([read=dict:clay write=dict:clay] q.r.u.riot)
            =/  dict-to-json=$-(dict:clay json)
              |=  permission=dict:clay
              %-  pairs:enjs:format
              :~  ['source' s+(spat src.permission)]
                  ['mode' s+(scot %tas mod.rul.permission)]
                  :-  'ships'
                  :-  %a
                  %+  turn
                    ~(tap in p.who.rul.permission)
                  |=  =ship
                  [%s (scot %p ship)]
                  :-  'groups'
                  :-  %a
                  %+  turn
                    ~(tap by q.who.rul.permission)
                  |=  [name=@ta ships=(set ship)]
                  %-  pairs:enjs:format
                  :~  ['name' s+name]
                      :-  'ships'
                      :-  %a
                      %+  turn
                        ~(tap in ships)
                      |=  =ship
                      [%s (scot %p ship)]
                  ==
              ==
            %-  en:json:html
            %-  pairs:enjs:format
            :~  ['read' (dict-to-json read.permissions)]
                ['write' (dict-to-json write.permissions)]
            ==
          %t
            %-  en:json:html
            :-  %a
            %+  turn
              !<((list path) q.r.u.riot)
            |=  =path
            [%s (spat path)]
          %u
            ?:  !<(? q.r.u.riot)
              'true'
            'false'
          %w
            =/  =cass:clay  !<(cass:clay q.r.u.riot)
            %-  en:json:html
            %-  pairs:enjs:format
            :~  ['revision' s+(scot %ud ud.cass)]
                ['date' s+(scot %da da.cass)]
            ==
          %z
            (en:json:html [%s (scot %uv !<(@uvI q.r.u.riot))])
        ==
      =/  result-mime=@t
        ?:  =(%x care.pole)
          ?~  riot
            'text/plain'
          (mark-mime p.r.u.riot)
        'application/json'
      :_  this
      %:  send-event
          eyre-id.pole
          %-  result:rpc
          :-  rpc-id.pole
          %-  pairs:enjs:format
          :~  :-  'contents'
              :-  %a
              :~  %-  pairs:enjs:format
                  :~  ['uri' s+uri.pole]
                      ['mimeType' s+result-mime]
                      :-  'text'
                      :-  %s
                      result-text
                  ==
              ==
          ==
      ==
    ==
  ::
      [%response %resource %http eyre-id=@ta rpc-id=@ta uri=@t ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%iris %http-response *]
      =/  =client-response:iris  client-response.sign-arvo
      ?+  -.client-response
        :_  this
        (send-event eyre-id.pole (internal:error:rpc rpc-id.pole 'Unexpected Iris response type' ~))
      ::
          %finished
        ?~  full-file.client-response
          :_  this
          (send-event eyre-id.pole (internal:error:rpc rpc-id.pole 'Empty HTTP response body' ~))
        =/  =response-header:http  response-header.client-response
        =/  content-type=@t
          ?~  content-type-header=(get-header:http 'content-type' headers.response-header)
            'text/plain'
          u.content-type-header
        =/  body-text=@t
          (rap 3 ~[q.data.u.full-file.client-response])
        :_  this
        %:  send-event
            eyre-id.pole
            %-  result:rpc
            :-  rpc-id.pole
            %-  pairs:enjs:format
            :~  :-  'contents'
                :-  %a
                :~  %-  pairs:enjs:format
                    :~  ['uri' s+uri.pole]
                        ['mimeType' s+content-type]
                        ['text' s+body-text]
                    ==
                ==
            ==
        ==
      ==
    ==
  ::
      [%response %resource %fine task=?(%chum %keen) eyre-id=@ta rpc-id=@ta uri=@t ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%ames %sage *]
      =/  =sage:mess:ames  sage.sign-arvo
      ?.  ?=(~ q.sage)
        :_  this
        (send-event eyre-id.pole (fine-result our.bowl q.byk.bowl now.bowl rpc-id.pole uri.pole q.sage))
      ?-    task.pole
          %chum
        :_  this
        %+  send-event
          eyre-id.pole
        %:  internal:error:rpc
            rpc-id.pole
            'Remote scry failed'
            `(frond:enjs:format %path s+(spat path.p.sage))
        ==
      ::
          %keen
        :_  this
        :~  :*  %pass
                /response/resource/fine/chum/[eyre-id.pole]/[rpc-id.pole]/[uri.pole]
                %arvo  %a  %chum
                p.sage
        ==  ==
      ==
    ==
  ==
++  on-watch
  |=  =(pole knot)
  ^-  (quip card _this)
  ?+    pole  (on-watch:def `path`pole)
      [%http-response eyre-id=@ta ~]
    `this
  ==
--
