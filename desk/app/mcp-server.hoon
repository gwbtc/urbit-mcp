/-  mcp, sole, spider
/+  dbug, verb, server, default-agent, pf=pretty-file, io=strandio,
    jut=json-utils, *rpc, beam-uri=uri-beam, fine-uri=uri-fine,
    scry-uri=uri-scry, aq=mcp-aqua, dj=mcp-dojo, ma=mcp-arguments,
    mm=mcp-mime, oa=mcp-oauth
::
::  default features are imported with /~
::  to force rebuilds when they're added or changed
/~  fil-tools     tool:mcp               /fil/mcp/tools
/~  fil-prompts   prompt:mcp             /fil/mcp/prompts
/~  fil-res-beam  resource:mcp           /fil/mcp/resources/beam
/~  fil-res-scry  resource:mcp           /fil/mcp/resources/scry
/~  fil-res-docs  resource:mcp           /fil/mcp/resources/urbit-docs
/~  fil-tpl-scry  template:resource:mcp  /fil/mcp/templates/scry
/~  fil-tpl-fine  template:resource:mcp  /fil/mcp/templates/fine
::
/$  tools-to-json      %mcp-tools      %json
/$  prompts-to-json    %mcp-prompts    %json
/$  resources-to-json  %mcp-resources  %json
/$  templates-to-json  %mcp-templates  %json
::
|%
::
::  replace .old entries with .new entries that share .key
++  merge-features
  |*  [new=(list) old=(set) key=$-(* *)]
  ^+  old
  ::  Empty old must exit before the skip gate below is built: its
  ::  sample type is _(head ~(tap in old)), and a $_ bunt EVALUATES
  ::  the expression — head of an empty tap crashes. Every fresh
  ::  install has empty sets, so on-init died in gall while upgrades
  ::  (non-empty state via on-load) sailed through. That asymmetry is
  ::  why this bug survived on long-lived ships.
  ?:  =(~ old)  (silt new)
  =/  keys  (silt (turn new key))
  %-  silt
  %+  weld  new
  %+  skip  ~(tap in old)
  |=(o=_(head ~(tap in old)) (~(has in keys) (key o)))
::
++  mcp-protocol-version  %'2026-07-28'
::
++  supported-versions  ~['2026-07-28' '2025-11-25']
::
::  required cache hints in ms
++  cache-ttl-lists     300.000
++  cache-ttl-discover  3.600.000
::
::  the raw json-rpc id travels on wires as a jammed @uw
++  cue-wire-id
  |=  t=@ta
  ^-  json
  ;;(json (cue (slav %uw t)))
::
::  generate mcp server info
++  server-info-json
  |=  our=@p
  ^-  json
  %-  pairs:enjs:format
  :~  ['name' s+(crip "{<our>} urbit mcp server")]
      ['version' s+'1.0.0']
  ==
::
::  wrap a result body with the fields the 2026-07-28 spec
::  requires on every result: resultType, server
::  identity in _meta, and caching hints when given
++  wrap-result
  |=  [our=@p id=json body=json cache=(unit @ud)]
  ^-  json
  ?>  ?=([%o *] body)
  =/  fields=(map @t json)  p.body
  =.  fields  (~(put by fields) 'resultType' s+'complete')
  =.  fields
    %+  ~(put by fields)  '_meta'
    (frond:enjs:format 'io.modelcontextprotocol/serverInfo' (server-info-json our))
  =?  fields  ?=(^ cache)
    %-  ~(gas by fields)
    :~  ['ttlMs' (numb:enjs:format u.cache)]
        ['cacheScope' s+'private']
    ==
  (result:rpc id [%o fields])
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
::
::  +local-desk: .desk if this ship has it, else %base
++  local-desk
  |=  [our=@p now=@da =desk]
  ^-  ^desk
  ?:  (~(has in .^((set ^desk) %cd /(scot %p our)//(scot %da now))) desk)
    desk
  %base
::
::  +read-card: answer resources/read with the page .get reads at .uri
::  and the thread's time, converted to %mime with the marks in the
::  beak .get names, or with .fail's json. both run on a thread, where
::  a failed scry in .get fails the thread instead of the agent's event
++  read-card
  |=  [our=@p eyre-id=@ta rpc-id=json uri=@t get=$-(@da [beak page]) fail=$-(tang json)]
  ^-  card
  :*  %pass  /response/resource/mime/[eyre-id]/(scot %uw (jam rpc-id))
      %arvo  %k  %lard  %base
      =/  m  (strand:spider ,vase)
      ^-  form:m
      ;<  now=@da  bind:m  get-time:io
      =/  [=beak =page]  (get now)
      ;<  res=(each mime tang)  bind:m  (page-to-mime:mm beak page)
      %-  pure:m
      !>  ^-  json
      ?-  -.res
        %|  (fail p.res)
      ::
          %&
        %:  wrap-result
            our
            rpc-id
            (frond:enjs:format 'contents' a+~[(contents:mm uri p.res)])
            `0
        ==
      ==
  ==
::
::  +clay-read: answer resources/read with a clay read of .uri,
::  converted with the marks in .desk or else pretty-printed
++  clay-read
  |=  [our=@p now=@da eyre-id=@ta rpc-id=json uri=@t =desk =riot:clay]
  ^-  (list card)
  ?~  riot
    %+  send-event
      eyre-id
    %:  wrap-result
        our
        rpc-id
        %+  frond:enjs:format
          'contents'
        :-  %a
        :~  %-  pairs:enjs:format
            :~  ['uri' s+uri]
                ['mimeType' s+'text/plain']
                ['text' s+'Failed to fetch file.']
            ==
        ==
        `0
    ==
  :_  ~
  %:  read-card
      our
      eyre-id
      rpc-id
      uri
      |=(@da [[our (local-desk our now desk) da+now] p.r.u.riot q.q.r.u.riot])
      |=  tang
      %:  wrap-result
          our
          rpc-id
          %+  frond:enjs:format
            'contents'
          :-  %a
          :~  %-  pairs:enjs:format
              :~  ['uri' s+uri]
                  ['mimeType' s+(mark-mime p.r.u.riot)]
                  :-  'text'
                  s+(of-wain:format (print-tang-to-wain (pretty-file:pf !<(noun q.r.u.riot))))
              ==
          ==
          `0
      ==
  ==
::
::  +fine-read: answer resources/read with a remote scry result,
::  converted with the marks of the matching local desk (or the local
::  agent's desk), else %base
++  fine-read
  |=  [our=@p now=@da eyre-id=@ta rpc-id=json uri=@t =spar:ames =page]
  ^-  card
  =/  pax=(pole knot)  path.spar
  =/  =desk
    %^  local-desk  our  now
    ?+  pax  %base
      [%c %x case=@ desk=@ *]  desk.pax
    ::
        [%g %x case=@ dude=@ *]
      =/  pre=path  /(scot %p our)/[dude.pax]/(scot %da now)/$
      ?.  .^(? %gu pre)
        %base
      .^(desk %gd pre)
    ==
  %:  read-card
      our
      eyre-id
      rpc-id
      uri
      |=(@da [[our desk da+now] page])
      |=  =tang
      %-  internal:error:rpc
      :+  rpc-id
        (of-wain:format (print-tang-to-wain tang))
      %-  some
      %-  pairs:enjs:format
      :~  ['uri' s+uri]
          ['mark' s+p.page]
          ['desk' s+desk]
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
        ['x-accel-buffering' 'no']
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
++  broadcast-list-changed
  |=  [=bowl:gall listeners=(map @ta listener) kind=?(%tools %prompts %resources)]
  ^-  (list card:agent:gall)
  =/  method=@t
    ?-  kind
      %tools      'notifications/tools/list_changed'
      %prompts    'notifications/prompts/list_changed'
      %resources  'notifications/resources/list_changed'
    ==
  %-  zing
  %+  murn
    ~(tap by listeners)
  |=  [eyre-id=@ta l=listener]
  ^-  (unit (list card:agent:gall))
  ?.  ?-  kind
        %tools      tools.l
        %prompts    prompts.l
        %resources  resources.l
      ==
    ~
  =/  live=?
    %+  lien
      ~(tap by sup.bowl)
    |=  [=duct =ship pat=path]
    =(pat /http-response/[eyre-id])
  ?.  live
    ~
  %-  some
  %+  send-sse-json
    eyre-id
  ^-  json
  %-  pairs:enjs:format
  :~  ['jsonrpc' s+'2.0']
      ['method' s+method]
      :-  'params'
      %-  frond:enjs:format
      :-  '_meta'
      (frond:enjs:format 'io.modelcontextprotocol/subscriptionId' sub-id.l)
  ==
::
::  +json-response: respond with status code and JSON body
::    Used for endpoints that must return JSON (e.g. OAuth discovery
::    at /.well-known/*) so MCP clients that probe per spec do not
::    choke trying to parse Eyre's HTML fallback as JSON.
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
::  +oauth-response: a response from the authorization server,
::  which no cache may store and no page may frame
++  oauth-response
  |=  $:  eyre-id=@ta
          status=@ud
          headers=(list [key=@t value=@t])
          body=(unit octs)
      ==
  ^-  (list card)
  %+  give-simple-payload:app:server
    eyre-id
  ^-  simple-payload:http
  :_  body
  :-  status
  %+  weld  headers
  :~  ['cache-control' 'no-store']
      ['x-frame-options' 'DENY']
  ==
::
+$  card  card:agent:gall
::
::  a live subscriptions/listen stream keyed by eyre-id; sub-id is
::  the raw json-rpc id of the listen request, echoed as the
::  subscription id on every notification
+$  listener
  $:  sub-id=json
      tools=?
      prompts=?
      resources=?
  ==
::
++  install-defaults
  |=  $:  old=state-3
          tools=(list tool:mcp)
          prompts=(list prompt:mcp)
          resources=(list resource:mcp)
          templates=(list template:resource:mcp)
      ==
  ^-  state-3
  %=  old
    tools      (merge-features tools tools.old |=(t=tool:mcp name.t))
    prompts    (merge-features prompts prompts.old |=(p=prompt:mcp name.p))
    resources  (merge-features resources resources.old |=(r=resource:mcp uri.r))
    templates  (merge-features templates templates.old |=(t=template:resource:mcp name.t))
  ==
::
::  +load-changed-cards: per-class list_changed notifications for the
::  classes whose feature set differs between .old and .new
::
++  load-changed-cards
  |=  [=bowl:gall old=state-3 new=state-3]
  ^-  (list card)
  %-  zing
  ^-  (list (list card))
  :~  ?:  =(tools.old tools.new)
        ~
      (broadcast-list-changed bowl listeners.old %tools)
    ::
      ?:  =(prompts.old prompts.new)
        ~
      (broadcast-list-changed bowl listeners.old %prompts)
    ::
      ?:  ?&  =(resources.old resources.new)
              =(templates.old templates.new)
          ==
        ~
      (broadcast-list-changed bowl listeners.old %resources)
  ==
+$  versioned-state
  $%  state-0
      state-1
      state-2
      state-3
  ==
+$  state-0
  $:  %0
      tools=(set tool:mcp)
      prompts=(set prompt:mcp)
      resources=(set resource:mcp)
      templates=(set template:resource:mcp)
      sse-sessions=(map @ta @t)
  ==
+$  state-1
  $:  %1
      tools=(set tool:mcp)
      prompts=(set prompt:mcp)
      resources=(set resource:mcp)
      templates=(set template:resource:mcp)
      sse-sessions=(map @ta @t)
      aqua=state:aq
      dojo=state:dj
  ==
+$  state-2
  $:  %2
      tools=(set tool:mcp)
      prompts=(set prompt:mcp)
      resources=(set resource:mcp)
      templates=(set template:resource:mcp)
      listeners=(map @ta listener)
      aqua=state:aq
      dojo=state:dj
  ==
+$  state-3
  $:  %3
      tools=(set tool:mcp)
      prompts=(set prompt:mcp)
      resources=(set resource:mcp)
      templates=(set template:resource:mcp)
      listeners=(map @ta listener)
      aqua=state:aq
      dojo=state:dj
      oauth=state:oa
  ==
::
::  support aqua workflows, persist dojo sessions
++  state-0-to-1
  |=  old=state-0
  ^-  state-1
  :*  %1
      tools.old
      prompts.old
      resources.old
      templates.old
      sse-sessions.old
      *state:aq
      *state:dj
  ==
::
::  MCP 2025-11-25 to 2026-07-28
::    remove .sse-sessions: sessionId deprecated by MCP 
::    add .listeners: subscriptionId added by MCP
++  state-1-to-2
  |=  old=state-1
  ^-  state-2
  :*  %2
      tools.old
      prompts.old
      resources.old
      templates.old
      ~
      aqua.old
      dojo.old
  ==
::
::  serve oauth: clients log in through the browser
++  state-2-to-3
  |=  old=state-2
  ^-  state-3
  :*  %3
      tools.old
      prompts.old
      resources.old
      templates.old
      listeners.old
      aqua.old
      dojo.old
      *state:oa
  ==
::
::  +dojo-drop: stop a held dojo session's
::  work, leave it, and kick its watchers
++  dojo-drop
  |=  [our=@p ses=@ta]
  ^-  (list card)
  :~  :*  %pass  /dojo/[ses]  %agent  [our %dojo]  %poke  %sole-action
          !>(`sole-action:sole`[[our (dojo-ses:dj ses)] %clr ~])
      ==
      [%pass /dojo/[ses] %agent [our %dojo] %leave ~]
      [%give %kick ~[/dojo/[ses]] ~]
  ==
::
::  +aqua-cleanup: stop and unsubscribe from one managed run;
::  the shared %aqua agent and its virtual ships stay up
++  aqua-cleanup
  |=  [our=@p id=@ta tid=@ta stop=?]
  ^-  (list card)
  %+  weld
    ^-  (list card)
    ?:  stop
      ~[[%pass /aqua/[id]/stop %agent [our %spider] %poke %spider-stop !>([tid |])]]
    ~
  ^-  (list card)
  :~  [%pass /aqua/[id]/result %agent [our %spider] %leave ~]
      [%pass /aqua/[id]/effects %agent [our %aqua] %leave ~]
  ==
::
::  +aqua-drain: mark a run %finishing and wake one tick from now
++  aqua-drain
  |=  [=bowl:gall aqua=state:aq id=@ta result=status:aq error=(unit @t)]
  ^-  (quip card state:aq)
  =/  r=run:aq
    (begin-finish:aq (~(got by runs.aqua) id) now.bowl error)
  :_  aqua(runs (~(put by runs.aqua) id r))
  ::  one logical tick in the future forces a new host kernel event.
  ::  poke acks can overtake pending facts in the current event's
  ::  worklist; an external behn wake cannot. no guest events or
  ::  quiet-period timer.
  :~  :*  %pass  /aqua-drain/[id]/(drain-branch:aq result)
          %arvo  %b  %wait  +(now.bowl)
      ==
  ==
::
::  +aqua-finish: record a run's final status and clean up after it
++  aqua-finish
  |=  $:  =bowl:gall
          aqua=state:aq
          id=@ta
          result=status:aq
          error=(unit @t)
          stop=?
      ==
  ^-  (quip card state:aq)
  :-  (aqua-cleanup our.bowl id tid:(~(got by runs.aqua) id) stop)
  (complete:aq aqua id now.bowl result error)
--
::
%-  agent:dbug
^-  agent:gall
=|  state-3
=*  state  -
%+  verb  |
|_  =bowl:gall
+*  this               .
    def                ~(. (default-agent this %|) bowl)
    default-tools      ~(val by fil-tools)
    default-prompts    ~(val by fil-prompts)
    default-templates  (weld ~(val by fil-tpl-scry) ~(val by fil-tpl-fine))
    default-resources  :(weld ~(val by fil-res-beam) ~(val by fil-res-scry) ~(val by fil-res-docs))
::
++  on-agent
  |=  [=(pole knot) =sign:agent:gall]
  ^-  (quip card _this)
  ?+    pole  (on-agent:def `wire`pole sign)
  ::
  ::  relay a held dojo session to the threads watching it
      [%dojo ses=@ta ~]
    ?-    -.sign
        %fact
      ?.  =(%sole-effect p.cage.sign)
        `this
      =/  got=(unit session:dj)  (~(get by dojo) ses.pole)
      ?~  got
        `this
      =/  new=(unit session:dj)
        (observe:dj u.got !<(sole-effect:sole q.cage.sign))
      ::  our clock has lost step with dojo's and cannot recover
      ?~  new
        %-  (slog leaf+"mcp: dojo session {(trip ses.pole)} lost sync; dropped" ~)
        :-  (dojo-drop our.bowl ses.pole)
        this(dojo (~(del by dojo) ses.pole))
      :-  [%give %fact ~[/dojo/[ses.pole]] cage.sign]~
      this(dojo (~(put by dojo) ses.pole u.new))
    ::
    ::  a rejected edit means our clock is wrong for good
        %poke-ack
      ?:  |(?=(~ p.sign) !(~(has by dojo) ses.pole))
        `this
      :-  (dojo-drop our.bowl ses.pole)
      this(dojo (~(del by dojo) ses.pole))
    ::
        %watch-ack
      ?~  p.sign
        `this
      :-  [%give %kick ~[/dojo/[ses.pole]] ~]~
      this(dojo (~(del by dojo) ses.pole))
    ::
        %kick
      :-  [%give %kick ~[/dojo/[ses.pole]] ~]~
      this(dojo (~(del by dojo) ses.pole))
    ==
  ::
      [%aqua id=@ta branch=@ta ~]
    =/  got=(unit run:aq)  (~(get by runs.aqua) id.pole)
    ?~  got
      `this
    =/  r=run:aq  u.got
    ?:  (terminal:aq status.r)
      `this
    =^  cards  aqua
      ^-  (quip card state:aq)
      ?-    -.sign
          %watch-ack
        ?^  p.sign
          (aqua-finish bowl aqua id.pole %failed `'subscription rejected' &)
        ?.  =(%result branch.pole)
          `aqua
        ?:  ?=(?(%cancelling %finishing) status.r)
          `aqua
        =.  r  r(status %running, updated now.bowl)
        `aqua(runs (~(put by runs.aqua) id.pole r))
      ::
          %poke-ack
        ?~  p.sign
          `aqua
        (aqua-finish bowl aqua id.pole %failed `'Spider rejected operation' &)
      ::
          %kick
        ?:  &(=(%result branch.pole) =(%finishing status.r))
          `aqua
        ?:  =(%cancelling status.r)
          (aqua-finish bowl aqua id.pole %cancelled ~ |)
        %:  aqua-finish
            bowl
            aqua
            id.pole
            %failed
            `'subscription closed unexpectedly'
            &
        ==
      ::
          %fact
        ?:  =(%effects branch.pole)
          ?.  =(%aqua-effect p.cage.sign)
            `aqua
          ::  decode the envelope first; runtime-specific tags are opaque
          =.  r  (observe:aq r now.bowl +.q.cage.sign)
          `aqua(runs (~(put by runs.aqua) id.pole r))
        ?.  =(%result branch.pole)
          `aqua
        ?:  =(%finishing status.r)
          `aqua
        ?+    p.cage.sign  `aqua
            %thread-done
          %:  aqua-drain
              bowl
              aqua
              id.pole
              ?:(=(%cancelling status.r) %cancelled %completed)
              ~
          ==
        ::
            %thread-fail
          ?:  =(%cancelling status.r)
            (aqua-drain bowl aqua id.pole %cancelled ~)
          =+  !<([term=@tas =tang] q.cage.sign)
          ::  never render a potentially enormous error tang here
          %:  aqua-drain
              bowl
              aqua
              id.pole
              %failed
              `(crip "Spider failure: %{(trip (end [3 128] term))}; tang omitted for brevity")
          ==
        ==
      ==
    [cards this]
  ==
::
++  on-leave
  |=  =path
  ^-  (quip card _this)
  ?.  ?=([%http-response @ ~] path)
    `this
  `this(listeners (~(del by listeners) i.t.path))
::
++  on-fail   on-fail:def
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  ::  Rebind /mcp on every load, not just on-init. An upgrade or a
  ::  nuke+revive runs on-load only, and without this card the main
  ::  endpoint 404s while /oauth and /.well-known keep working — the
  ::  agent looks healthy in +vats and serves nothing.
  =/  mcp-card=card
    :*  %pass  /eyre/connect
        %arvo  %e  %connect
        [`/mcp dap.bowl]
    ==
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
  =/  migrated=state-3
    ?-  -.old
      %0  (state-2-to-3 (state-1-to-2 (state-0-to-1 old)))
      %1  (state-2-to-3 (state-1-to-2 old))
      %2  (state-2-to-3 old)
      %3  old
    ==
  ::  a reload orphans the active run's thread; stop and close it
  =^  cleanup=(list card)  aqua.migrated
    ?~  active.aqua.migrated
      `aqua.migrated
    %:  aqua-finish
        bowl
        aqua.migrated
        u.active.aqua.migrated
        %interrupted
        `'agent reloaded; managed thread stopped'
        &
    ==
  =/  new=state-3
    %:  install-defaults
        migrated
        default-tools
        default-prompts
        default-resources
        default-templates
    ==
  :_  this(state new)
  %+  weld
    ^-  (list card)
    :~  mcp-card
        oauth-card
        well-known-card
    ==
  (weld cleanup (load-changed-cards bowl migrated new))
::
++  on-init
  ^-  (quip card _this)
  :_  %=  this
        state  %-  install-defaults
               :*  state
                   default-tools
                   default-prompts
                   default-resources
                   default-templates
               ==
      ==
  :~  :*  %pass  /eyre/connect
          %arvo  %e  %connect
          [`/mcp dap.bowl]
      ==
      ::  Bind /.well-known to serve the OAuth discovery documents
      ::  MCP clients probe for; without a binding Eyre redirects to
      ::  /apps/landscape/ (HTML), and the client errors trying to
      ::  parse HTML as JSON.
      ::
      :*  %pass  /eyre/connect/well-known
          %arvo  %e  %connect
          [[~ ~['.well-known']] dap.bowl]
      ==
      ::  Bind /oauth for the authorization server's register,
      ::  authorize and token endpoints.
      ::
      :*  %pass  /eyre/connect/oauth
          %arvo  %e  %connect
          [[~ ~['oauth']] dap.bowl]
      ==
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^  ?+  mark
        (on-poke:def mark vase)
          ::  dojo/* tool threads send lines to, and close,
          ::  the dojo sessions this agent holds
          %mcp-dojo
        ?>  =(src our):bowl
        =/  act=action:dj  !<(action:dj vase)
        ?-    -.act
            %close
          :-  (dojo-drop our.bowl ses.act)
          this(dojo (~(del by dojo) ses.act))
        ::
            %clear
          ?>  (~(has by dojo) ses.act)
          :_  this
          :~  :*  %pass  /dojo/[ses.act]  %agent  [our.bowl %dojo]  %poke
                  %sole-action
                  !>(`sole-action:sole`[[our.bowl (dojo-ses:dj ses.act)] %clr ~])
              ==
          ==
        ::
            %input
          =/  old=session:dj  (~(got by dojo) ses.act)
          ?>  ready.old
          =^  cal=sole-change:sole  old  (input:dj old now.bowl txt.act)
          =/  id=sole-id:sole  [our.bowl (dojo-ses:dj ses.act)]
          :_  this(dojo (~(put by dojo) ses.act old))
          :~  :*  %pass  /dojo/[ses.act]  %agent  [our.bowl %dojo]
                  %poke  %sole-action  !>(`sole-action:sole`[id %det cal])
              ==
              :*  %pass  /dojo/[ses.act]  %agent  [our.bowl %dojo]
                  %poke  %sole-action  !>(`sole-action:sole`[id %ret ~])
              ==
          ==
        ==
      ::
          ::  the aqua/* tool threads return at once, so this agent
          ::  holds each run's subscriptions and captured effects
          %mcp-aqua
        ?>  =(src our):bowl
        =/  act=action:aq  !<(action:aq vase)
        ?-    -.act
            %start
          ?>  ?=(~ active.aqua)
          ?>  !(~(has by runs.aqua) id.act)
          ?>  &((lte (met 3 id.act) 128) (lte (met 3 desk.act) 128) (lte (met 3 term.act) 128))
          ?>  (lte (lent effects.act) 16)
          ?>  (levy effects.act |=(e=@tas (matches-effect:aq supported-effects:aq e)))
          =/  kept=state:aq  (retain:aq aqua)
          =/  tid=@ta  (cat 3 'mcp-aqua-' id.act)
          =/  r=run:aq
            [id.act tid desk.act term.act %starting now.bowl now.bowl 0 0 0 ~ ~ effects.act 0 ~]
          :_  this(aqua kept(runs (~(put by runs.kept) id.act r), active `id.act))
          :~  [%pass /aqua/[id.act]/effects %agent [our.bowl %aqua] %watch /effect]
              [%pass /aqua/[id.act]/result %agent [our.bowl %spider] %watch /thread-result/[tid]]
              :*  %pass  /aqua/[id.act]/start  %agent  [our.bowl %spider]  %poke
                  %spider-start  !>([~ `tid [our.bowl desk.act da+now.bowl] term.act arg.act])
              ==
          ==
        ::
            %cancel
          =/  r=run:aq  (~(got by runs.aqua) id.act)
          ?:  |((terminal:aq status.r) ?=(?(%cancelling %finishing) status.r))  `this
          =/  pending=run:aq  r
          =.  pending  pending(status %cancelling, updated now.bowl)
          :_  this(aqua aqua(runs (~(put by runs.aqua) id.act pending)))
          ~[[%pass /aqua/[id.act]/stop %agent [our.bowl %spider] %poke %spider-stop !>([tid.r |])]]
        ::
            %release
          =/  r=run:aq  (~(got by runs.aqua) id.act)
          ?>  (terminal:aq status.r)
          `this(aqua aqua(runs (~(del by runs.aqua) id.act)))
        ==
      ::
          %handle-http-request
        (handle-req !<([@ta inbound-request:eyre] vase))
      ::
      ::  forget every oauth client and token; each client must
      ::  register and win the user's consent again
          %revoke-oauth
        ?>  =(src our):bowl
        `this(oauth *state:oa)
      ::
          ?(%import-tools %import-prompts %import-resources %import-templates)
        ?>  =(src our):bowl
        =/  desk=@t  !<(@t vase)
        =/  kind=?(%tools %prompts %resources)
          ?-  mark
            %import-tools      %tools
            %import-prompts    %prompts
            %import-resources  %resources
            %import-templates  %resources
          ==
        :-  (broadcast-list-changed bowl listeners kind)
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
        =/  kind=?(%tools %prompts %resources)
          ?-  mark
            %add-tool      %tools
            %add-prompt    %prompts
            %add-resource  %resources
            %add-template  %resources
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
            (broadcast-list-changed bowl listeners kind)
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
      ::
      ::  delete the feature with the key the add pokes replace on:
      ::  a resource's uri, or the name of a tool, prompt or template
          ?(%delete-tool %delete-prompt %delete-resource %delete-template)
        ?>  =(src our):bowl
        =/  key=@t  !<(@t vase)
        =/  new=state-3
          ?-    mark
              %delete-tool
            %=  state
              tools  %-  silt
                     %+  skip
                       ~(tap in tools)
                     |=(old=tool:mcp =(key name.old))
            ==
          ::
              %delete-prompt
            %=  state
              prompts  %-  silt
                       %+  skip
                         ~(tap in prompts)
                       |=(old=prompt:mcp =(key name.old))
            ==
          ::
              %delete-resource
            %=  state
              resources  %-  silt
                         %+  skip
                           ~(tap in resources)
                         |=(old=resource:mcp =(key uri.old))
            ==
          ::
              %delete-template
            %=  state
              templates  %-  silt
                         %+  skip
                           ~(tap in templates)
                         |=(old=template:resource:mcp =(key name.old))
            ==
          ==
        ::  deleting a feature we do not have is not a list change
        :_  this(state new)
        ?:  =(state new)
          ~
        %^  broadcast-list-changed  bowl  listeners
        ?-  mark
          %delete-tool      %tools
          %delete-prompt    %prompts
          %delete-resource  %resources
          %delete-template  %resources
        ==
      ==
  ::  +handle-oauth: the authorization server. Eyre's login page
  ::  checks +code; we register clients, ask the user's consent,
  ::  and trade codes and refresh tokens for access tokens.
  ::
  ++  handle-oauth
    |=  [eyre-id=@ta req=inbound-request:eyre site=tape base=@t]
    ^-  (quip card _this)
    =.  oauth  (prune:oa oauth now.bowl)
    =/  method=@t  method.request.req
    =/  as-html=(list [key=@t value=@t])
      ['content-type' 'text/html; charset=utf-8']~
    =/  as-json=(list [key=@t value=@t])
      ['content-type' 'application/json']~
    ::  RFC 7591 dynamic client registration
    ::
    ?:  &(=("/oauth/register" site) =('POST' method))
      =/  jon=json
        ?~  body.request.req
          ~
        (fall (de:json:html q.u.body.request.req) ~)
      =/  new=(unit [id=@t state:oa])
        =/  redirects=(unit (list @t))
          ((ot ~[['redirect_uris' (ar so)]]):dejs-soft:format jon)
        ?~  redirects
          ~
        %:  register:oa
            oauth
            now.bowl
            eny.bowl
            (fall ((ot ~[['client_name' so]]):dejs-soft:format jon) '')
            u.redirects
        ==
      ?~  new
        :_  this
        %:  oauth-response
            eyre-id
            400
            as-json
            %-  some
            %-  as-octs:mimes:html
            %-  en:json:html
            %-  pairs:enjs:format
            :~  ['error' s+'invalid_client_metadata']
                ['error_description' s+'redirect_uris missing or malformed']
            ==
        ==
      =/  =client:oa  (~(got by clients.+.u.new) id.u.new)
      :_  this(oauth +.u.new)
      %:  oauth-response
          eyre-id
          201
          as-json
          %-  some
          %-  as-octs:mimes:html
          %-  en:json:html
          %-  pairs:enjs:format
          :~  ['client_id' s+id.u.new]
              ['client_name' s+name.client]
              ['redirect_uris' a+(turn redirects.client |=(r=@t s+r))]
              ['token_endpoint_auth_method' s+'none']
              ['grant_types' a+~[s+'authorization_code' s+'refresh_token']]
              ['response_types' a+~[s+'code']]
          ==
      ==
    ::  the user's browser arrives here from the client
    ::
    ?:  &(=("/oauth/authorize" site) =('GET' method))
      =/  args=(map @t @t)  (parse-query:oa url.request.req)
      =/  client-id=@t  (~(gut by args) 'client_id' '')
      =/  redirect=@t   (~(gut by args) 'redirect_uri' '')
      ::  never redirect to an address the client did not register
      ?.  (registered:oa oauth client-id redirect)
        :_  this
        %:  oauth-response
            eyre-id
            400
            as-html
            %-  some
            %-  error-page:oa
            "This ship does not know that client or its redirect address. Remove the server from your MCP client, add it again, and retry."
        ==
      =/  opaque=(unit @t)  (~(get by args) 'state')
      =/  challenge=@t  (~(gut by args) 'code_challenge' '')
      ?.  ?&  =('code' (~(gut by args) 'response_type' ''))
              =('S256' (~(gut by args) 'code_challenge_method' ''))
              !=('' challenge)
          ==
        :_  this
        %:  oauth-response
            eyre-id
            303
            :~  :-  'location'
                %+  callback:oa  redirect
                :-  ['error' 'invalid_request']
                ?~(opaque ~ ['state' u.opaque]~)
            ==
            ~
        ==
      ::  Eyre's login page takes +code and sends the browser back
      ::  here. Encode our whole url: Eyre would cut a bare one at
      ::  its first '&'.
      ?.  authenticated.req
        :_  this
        %:  oauth-response
            eyre-id
            307
            :~  :-  'location'
                %+  rap  3
                :~  '/~/login?redirect='
                    (crip (en-urlt:html (trip url.request.req)))
                ==
            ==
            ~
        ==
      =^  id=@t  oauth
        %:  open-request:oa
            oauth
            now.bowl
            eny.bowl
            client-id
            [redirect challenge opaque]
        ==
      :_  this
      %:  oauth-response
          eyre-id
          200
          as-html
          %-  some
          %:  consent-page:oa
              our.bowl
              name:(~(got by clients.oauth) client-id)
              id
          ==
      ==
    ::  the consent form posts back here. Eyre's cookie rides along
    ::  on posts from any site, so the form must come from our own
    ::  page: same origin, carrying a request id only we showed.
    ::
    ?:  &(=("/oauth/authorize" site) =('POST' method))
      ?.  ?&  authenticated.req
              =(`base (get-header:http 'origin' header-list.request.req))
          ==
        [(oauth-response eyre-id 403 ~ ~) this]
      =/  form=(map @t @t)  (parse-form:oa body.request.req)
      =/  id=@t  (~(gut by form) 'request' '')
      =/  done=(unit [url=@t state:oa])
        ?:  =('allow' (~(gut by form) 'choice' ''))
          (approve:oa oauth now.bowl eny.bowl id)
        (deny:oa oauth now.bowl id)
      ?~  done
        :_  this
        %:  oauth-response
            eyre-id
            400
            as-html
            %-  some
            %-  error-page:oa
            "This request has expired. Start again from your MCP client."
        ==
      :_  this(oauth +.u.done)
      (oauth-response eyre-id 303 ['location' url.u.done]~ ~)
    ::  the client trades a code or a refresh token for tokens
    ::
    ?:  &(=("/oauth/token" site) =('POST' method))
      =/  form=(map @t @t)  (parse-form:oa body.request.req)
      =/  client-id=@t   (~(gut by form) 'client_id' '')
      =/  grant-type=@t  (~(gut by form) 'grant_type' '')
      ::  a client we evicted must learn to register again
      ?.  (~(has by clients.oauth) client-id)
        :_  this
        %:  oauth-response
            eyre-id
            401
            as-json
            %-  some
            %-  as-octs:mimes:html
            (en:json:html (pairs:enjs:format ~[['error' s+'invalid_client']]))
        ==
      ?.  ?=(?(%'authorization_code' %'refresh_token') grant-type)
        :_  this
        %:  oauth-response
            eyre-id
            400
            as-json
            %-  some
            %-  as-octs:mimes:html
            %-  en:json:html
            (pairs:enjs:format ~[['error' s+'unsupported_grant_type']])
        ==
      =^  got=(unit tokens:oa)  oauth
        ?-    grant-type
            %'authorization_code'
          %:  redeem:oa
              oauth
              now.bowl
              eny.bowl
              client-id
              (~(gut by form) 'code' '')
              (~(get by form) 'redirect_uri')
              (~(gut by form) 'code_verifier' '')
          ==
        ::
            %'refresh_token'
          %:  renew:oa
              oauth
              now.bowl
              eny.bowl
              client-id
              (~(gut by form) 'refresh_token' '')
          ==
        ==
      :_  this
      ?~  got
        %:  oauth-response
            eyre-id
            400
            as-json
            %-  some
            %-  as-octs:mimes:html
            (en:json:html (pairs:enjs:format ~[['error' s+'invalid_grant']]))
        ==
      %:  oauth-response
          eyre-id
          200
          as-json
          %-  some
          %-  as-octs:mimes:html
          %-  en:json:html
          %-  pairs:enjs:format
          :~  ['access_token' s+access.u.got]
              ['token_type' s+'Bearer']
              ['expires_in' (numb:enjs:format (div access-ttl:oa ~s1))]
              ['refresh_token' s+refresh.u.got]
          ==
      ==
    :_  this
    %:  oauth-response
        eyre-id
        404
        as-json
        %-  some
        %-  as-octs:mimes:html
        (en:json:html (pairs:enjs:format ~[['error' s+'not found']]))
    ==
  ::
  ++  handle-req
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  url-tape=tape  (trip url.request.req)
    ::  the url's path, without its query
    =/  site=tape
      (scag (fall (find "?" url-tape) (lent url-tape)) url-tape)
    =/  headers=header-list:http  header-list.request.req
    =/  host=@t  (fall (get-header:http 'host' headers) 'localhost')
    ::  our own origin, as the client sees it; a proxy that ends
    ::  tls in front of us says so in x-forwarded-proto
    =/  base=@t
      %+  rap  3
      :~  ?:  ?|  secure.req
                  =(`'https' (get-header:http 'x-forwarded-proto' headers))
              ==
            'https://'
          'http://'
          host
      ==
    ::
    ::  Reject browser origins that do not correspond to this
    ::  endpoint, the local machine, or our EAuth URL.
    =/  origin=(unit @t)  (get-header:http 'origin' headers)
    =/  origin-allowed=?
      ?~  origin
        .y
      ?:  =(u.origin base)
        .y
      ?:  (loopback-authority (trip host))
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
    ::  OAuth discovery: RFC 9728 protected-resource metadata names
    ::  us as our own authorization server. Clients ask for it at
    ::  the bare path and at the path suffixed with the resource's.
    ::
    ?:  ?|  =("/.well-known/oauth-protected-resource" site)
            =("/.well-known/oauth-protected-resource/mcp" site)
        ==
      [(json-response eyre-id 200 (resource-meta:oa base)) this]
    ?:  =("/.well-known/oauth-authorization-server" site)
      [(json-response eyre-id 200 (server-meta:oa base)) this]
    ::  Any other /.well-known/* probe gets a JSON 404.
    ::
    ?:  =("/.well-known" (scag 12 site))
      :_  this
      (json-response eyre-id 404 (pairs:enjs:format ~[['error' s+'not found']]))
    ?:  =("/oauth" (scag 6 site))
      (handle-oauth eyre-id req site base)
    ::  /mcp takes an Eyre session (cookie) or one of our own OAuth
    ::  access tokens. The 401 points the client at the metadata
    ::  above, which starts its OAuth flow.
    ::
    =/  token=(unit @t)  (bearer:oa headers)
    ?.  ?|  authenticated.req
            &(?=(^ token) (check:oa oauth now.bowl u.token))
        ==
      :_  this
      %^  simple-response  eyre-id  401
      :~  :-  'www-authenticate'
          %+  rap  3
          :~  'Bearer resource_metadata="'
              base
              '/.well-known/oauth-protected-resource"'
              ?~(token '' ', error="invalid_token"')
          ==
      ==
    ?+  method.request.req
      [(simple-response eyre-id 405 ~[['allow' 'POST']]) this]
    ::
        %'POST'
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
        =/  id=(unit json)      (~(get jo:jut jon) /id)
        ?~  id
          ::  a request with no id is an MCP 2025-11-25 notification
          :_  this
          (json-response eyre-id 400 (request:error:rpc ~ 'Missing JSON RPC request ID' ~))
        ?.  ?=(?([%n *] [%s *]) u.id)
          :_  this
          (json-response eyre-id 400 (request:error:rpc ~ 'Invalid JSON RPC request ID' ~))
        ?.  ?=([~ %s *] method)
          :_  this
          (json-response eyre-id 400 (request:error:rpc u.id 'Missing or invalid method' ~))
        ::
        ::  MCP 2026-07-28 requests come with their protocol version
        =/  header-version=(unit @t)
          (get-header:http 'mcp-protocol-version' header-list.request.req)
        =/  invalid=(unit json)
          ?:  ?|  ?=(~ header-version)
                  =(%'2025-11-25' u.header-version)
                  =(%'2025-06-18' u.header-version)
                  =(%'2025-03-26' u.header-version)
                  =(%'2024-11-05' u.header-version)
              ==
            ~
          ?.  =(mcp-protocol-version u.header-version)
            `(version:error:rpc u.id u.header-version supported-versions)
          =/  meta=(map @t json)
            =/  params=(unit json)  (~(get jo:jut jon) /params)
            ?.  ?=([~ %o *] params)  ~
            =/  m=(unit json)  (~(get by p.u.params) '_meta')
            ?.  ?=([~ %o *] m)  ~
            p.u.m
          =/  meta-version=(unit @t)
            =/  v=(unit json)
              (~(get by meta) 'io.modelcontextprotocol/protocolVersion')
            ?.  ?=([~ %s *] v)  ~
            `p.u.v
          ?~  meta-version
            :-  ~
            %:  params:error:rpc
                u.id
                'Missing io.modelcontextprotocol/protocolVersion in _meta'
                ~
            ==
          ?.  =(u.header-version u.meta-version)
            `(header:error:rpc u.id 'MCP-Protocol-Version header does not match _meta' ~)
          =/  header-method=(unit @t)
            (get-header:http 'mcp-method' header-list.request.req)
          ?~  header-method
            `(header:error:rpc u.id 'Missing Mcp-Method header' ~)
          ?.  =(u.header-method p.u.method)
            `(header:error:rpc u.id 'Mcp-Method header does not match method' ~)
          ?.  (~(has by meta) 'io.modelcontextprotocol/clientCapabilities')
            :-  ~
            %:  params:error:rpc
                u.id
                'Missing io.modelcontextprotocol/clientCapabilities in _meta'
                ~
            ==
          ::  tools/call, prompts/get and resources/read must also
          ::  name their target in the mcp-name header
          ?:  ?&  ?=(?(%'tools/call' %'prompts/get' %'resources/read') p.u.method)
                  =/  want-name=(unit @t)
                    ?:  =(%'resources/read' p.u.method)
                      (~(deg jo:jut jon) /params/uri so:dejs:format)
                    (~(deg jo:jut jon) /params/name so:dejs:format)
                  =/  header-name=(unit @t)
                    (get-header:http 'mcp-name' header-list.request.req)
                  ?|  ?=(~ header-name)
                      ?!  .=  want-name
                          =/  t=tape  (trip (need header-name))
                          ?.  ?&  (gte (lent t) 11)
                                  =("=?base64?" (scag 9 t))
                                  =("?=" (slag (sub (lent t) 2) t))
                              ==
                            header-name
                          =/  dec
                            (de:base64:mimes:html (crip (swag [9 (sub (lent t) 11)] t)))
                          ?~  dec
                            header-name
                          `q.u.dec
                  ==
              ==
            `(header:error:rpc u.id 'Mcp-Name header missing or does not match request body' ~)
          ~
        ?^  invalid
          :_  this
          (json-response eyre-id 400 u.invalid)
        ?+  method
          :_  this
          (json-response eyre-id 404 (method:error:rpc u.id 'Method not found' ~))
        ::
        ::  legacy 2025-11-25 handshake
            [~ [%s %'initialize']]
          =/  requested=(unit @t)
            (~(deg jo:jut jon) /params/'protocolVersion' so:dejs:format)
          =/  negotiated=@t
            ?:  ?&  ?=(^ requested)
                    ?=(^ (find ~[(need requested)] supported-versions))
                ==
              (need requested)
            %'2025-11-25'
          :_  this
          %+  send-event  eyre-id
          %-  result:rpc
          :-  u.id
          %-  pairs:enjs:format
          :~  ['protocolVersion' s+negotiated]
              :-  'capabilities'
              %-  pairs:enjs:format
              :~  ['tools' (frond:enjs:format 'listChanged' b+&)]
                  ['prompts' (frond:enjs:format 'listChanged' b+&)]
                  :-  'resources'
                  %-  pairs:enjs:format
                  :~  ['subscribe' b+|]
                      ['listChanged' b+&]
                  ==
              ==
              ['serverInfo' (server-info-json our.bowl)]
          ==
        ::
            [~ [%s %'ping']]
          ::  pre-2026 keepalive
          :_  this
          (send-event eyre-id (result:rpc u.id o+~))
        ::
            [~ [%s %'server/discover']]
          :_  this
          %+  send-event  eyre-id
          %-  wrap-result
          :^  our.bowl  u.id
            %-  pairs:enjs:format
            :~  ['supportedVersions' a+(turn supported-versions |=(v=@t s+v))]
                :-  'capabilities'
                %-  pairs:enjs:format
                :~  ['tools' (frond:enjs:format 'listChanged' b+&)]
                    ['prompts' (frond:enjs:format 'listChanged' b+&)]
                    ['resources' (frond:enjs:format 'listChanged' b+&)]
                ==
            ==
          `cache-ttl-discover
        ::
            [~ [%s %'subscriptions/listen']]
          ::  a long-lived sse stream of opted-in change
          ::  notifications; the client cancels by closing it
          ?.  ?=(^ (find "text/event-stream" (trip u.accept)))
            :_  this
            %^  json-response  eyre-id  406
            (request:error:rpc u.id 'Accept must include text/event-stream' ~)
          =/  l=listener
            :*  u.id
                %+  fall
                  (~(deg jo:jut jon) /params/notifications/'toolsListChanged' bo:dejs:format)
                |
                %+  fall
                  (~(deg jo:jut jon) /params/notifications/'promptsListChanged' bo:dejs:format)
                |
                %+  fall
                  (~(deg jo:jut jon) /params/notifications/'resourcesListChanged' bo:dejs:format)
                |
            ==
          ::  the ack grants the subset we support; resource
          ::  subscriptions are declined by omission
          =/  ack=json
            %-  pairs:enjs:format
            :~  ['jsonrpc' s+'2.0']
                ['method' s+'notifications/subscriptions/acknowledged']
                :-  'params'
                %-  pairs:enjs:format
                :~  :-  '_meta'
                    (frond:enjs:format 'io.modelcontextprotocol/subscriptionId' u.id)
                    :-  'notifications'
                    %-  pairs:enjs:format
                    %+  murn
                      :~  ['toolsListChanged' tools.l]
                          ['promptsListChanged' prompts.l]
                          ['resourcesListChanged' resources.l]
                      ==
                    |=  [k=@t v=?]
                    ^-  (unit [@t json])
                    ?.(v ~ `[k b+&])
                ==
            ==
          :_  this(listeners (~(put by listeners) eyre-id l))
          ;:  weld
            (send-sse-start eyre-id)
            (send-sse-json eyre-id ack)
            ~[(set-keepalive now.bowl eyre-id)]
          ==
        ::
            [~ [%s %'tools/list']]
          :_  this
          %+  send-event  eyre-id
          %-  wrap-result
          :^  our.bowl  u.id
            (tools-to-json ~(tap in tools))
          `cache-ttl-lists
        ::
            [~ [%s %'resources/list']]
          :_  this
          %+  send-event  eyre-id
          %-  wrap-result
          :^  our.bowl  u.id
            (resources-to-json ~(tap in resources))
          `cache-ttl-lists
        ::
            [~ [%s %'resources/templates/list']]
          :_  this
          %+  send-event  eyre-id
          %-  wrap-result
          :^  our.bowl  u.id
            (templates-to-json ~(tap in templates))
          `cache-ttl-lists
        ::
            [~ [%s %'prompts/list']]
          :_  this
          %+  send-event  eyre-id
          %-  wrap-result
          :^  our.bowl  u.id
            (prompts-to-json ~(tap in prompts))
          `cache-ttl-lists
        ::
            [~ [%s %'resources/read']]
          =/  rpc-wire-id=@ta  (scot %uw (jam u.id))
          =/  uri=(unit @t)
            (~(deg jo:jut jon) /params/uri so:dejs:format)
          ?~  uri
            :_  this
            (send-event eyre-id (params:error:rpc u.id 'Missing or invalid resource URI' ~))
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
                    u.id
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
                      u.id
                      'Invalid beam'
                      `(frond:enjs:format %uri s+u.uri)
              ==  ==
            :_  this
            :~  :*  %pass
                    /response/resource/beam/[eyre-id]/[rpc-wire-id]/[u.uri]
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
            :_  this
            :~  :*  %pass
                    /response/resource/http/[eyre-id]/[rpc-wire-id]/[u.uri]
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
                  u.id
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
                    u.id
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
                      u.id
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
                      u.id
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
                  (send-event eyre-id (internal:error:rpc u.id (crip (print-tang-to-wain (tang p.scry-result))) ~))
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
                    %-  wrap-result
                    :^  our.bowl  u.id
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
                    `0
                ==
              ::
                  %x
                ::  a thread reads the scry and converts its mark to
                ::  %mime with the marks in the agent's desk
                :_  this
                :_  ~
                %:  read-card
                    our.bowl
                    eyre-id
                    u.id
                    u.uri
                    |=  now=@da
                    =/  prefix=path
                      /(scot %p our.bowl)/[(head scry-path)]/(scot %da now)
                    :-  [our.bowl .^(desk %gd (snoc prefix %$)) da+now]
                    :-  (slav %tas (rear scry-path))
                    .^(* %gx (welp prefix (slag 1 scry-path)))
                    |=  =tang
                    %:  internal:error:rpc
                        u.id
                        (of-wain:format (print-tang-to-wain tang))
                        `(frond:enjs:format %uri s+u.uri)
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
                      u.id
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
                      u.id
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
                  (send-event eyre-id (internal:error:rpc u.id (crip (print-tang-to-wain (tang p.scry-result))) ~))
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
                    %-  wrap-result
                    :^  our.bowl  u.id
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
                    `0
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
                      u.id
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
                        /response/resource/scry/clay/[care]/[eyre-id]/[rpc-wire-id]/[u.uri]
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
                      u.id
                      'Invalid Clay scry path'
                      `(frond:enjs:format %uri s+u.uri)
                  ==
                :_  this
                :~  :*  %pass
                        /response/resource/scry/clay/x/[eyre-id]/[rpc-wire-id]/[u.uri]
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
              (send-event eyre-id (request:error:rpc u.id (crip "Invalid fine URI {<u.uri>}") ~))
            :_  this
            :~  :*  %pass
                    /response/resource/fine/keen/[eyre-id]/[rpc-wire-id]/[u.uri]
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
            (send-event eyre-id (params:error:rpc u.id 'Missing or invalid prompt name' ~))
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
                u.id
                'Prompt not found'
                `(frond:enjs:format %name s+u.prompt-name)
            ==
          ?:  (gth 1 (lent prompt-results))
            :_  this
            %+  send-event
              eyre-id
            %:  internal:error:rpc
                u.id
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
              %-  wrap-result
              :^  our.bowl  u.id
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
              ~
          ==
        ::
            [~ [%s %'tools/call']]
          :_  this
          =/  tool-name=(unit @t)
            (~(deg jo:jut jon) /params/name so:dejs:format)
          ?~  tool-name
            (send-event eyre-id (params:error:rpc u.id 'Missing or invalid tool name' ~))
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
                u.id
                'Tool not found'
                `(frond:enjs:format %name s+u.tool-name)
            ==
          ?:  (gth 1 (lent tool-results))
            %+  send-event
              eyre-id
            %:  internal:error:rpc
                u.id
                'Multiple tools found'
                `(frond:enjs:format %name s+u.tool-name)
            ==
          =/  arguments=(unit json)  (~(get jo:jut jon) /params/arguments)
          ?~  arguments
            (send-event eyre-id (params:error:rpc u.id 'Missing arguments' ~))
          =/  args-map=(unit (map @t json))
            ?:  ?=([%o *] u.arguments)
              `p.u.arguments
            ~
          ?~  args-map
            (send-event eyre-id (params:error:rpc u.id 'Invalid arguments' ~))
          =/  parsed=(unit (map @t argument:tool:mcp))
            (parse-args:ma u.args-map)
          ?~  parsed
            (send-event eyre-id (params:error:rpc u.id 'Invalid tool arguments: numbers must be unsigned decimal integers' ~))
          ^-  (list card)
          ::  When the client accepts SSE (the MCP streamable-HTTP spec
          ::  says it must for POST), answer with an SSE stream and ping
          ::  it on a timer so long-running tools don't lose the
          ::  connection before the thread finishes.
          ::
          =/  sse=?  ?=(^ (find "text/event-stream" (trip u.accept)))
          =/  mode=@ta  ?:(sse %sse %plain)
          =/  run-tool=card
            :*  %pass  /response/tool/[eyre-id]/(scot %uw (jam u.id))/[mode]
                %arvo  %k
                %lard  q.byk.bowl
                %-  thread-builder.i.tool-results
                u.parsed
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
    ::  .^((unit ?) %gx /=mcp-server=/dojo/[ses]/noun)
    ::  ~ if no such session is held, else whether it will take a line
      [%x %dojo ses=@ta ~]
    :^  ~  ~  %noun
    !>  ^-  (unit ?)
    (bind (~(get by dojo) ses.pole) |=(s=session:dj ready.s))
    ::
      [%x %aqua %read encoded=@ta ~]
    ::  Tool encodes a small query in the scry path; no query state needed.
    ?>  (lte (met 3 encoded.pole) 4.096)
    =/  q=query:aq  ;;(query:aq (cue (slav %uv encoded.pole)))
    ?>  &((lte (lent ships.q) 32) (lte (lent effects.q) 16) (lte (met 3 id.q) 128))
    ``json+!>((read-json:aq aqua q))
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
      [%aqua-drain id=@ta branch=@tas ~]
    ?>  ?=([%behn %wake *] sign-arvo)
    =/  wake-error=(unit tang)  +>.sign-arvo
    =/  got=(unit run:aq)  (~(get by runs.aqua) id.pole)
    ?~  got
      `this
    ?.  =(%finishing status.u.got)
      `this
    =/  result=(unit status:aq)  (drain-result:aq branch.pole)
    ?~  result
      `this
    =^  cards  aqua
      ?~  wake-error
        (aqua-finish bowl aqua id.pole u.result error.u.got |)
      (aqua-finish bowl aqua id.pole %failed `'completion wake failed' &)
    [cards this]
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
    =/  rpc-id=json  (cue-wire-id rpc-id.pole)
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%khan %arow *]
      ?:  ?=(%.n -.p.sign-arvo)
        :_  this
        %-  finish
        (internal:error:rpc rpc-id (crip (print-tang-to-wain tang.p.p.sign-arvo)) ~)
      ?>  ?=([%khan %arow %.y %noun *] sign-arvo)
      =/  [%khan %arow %.y %noun =vase]  sign-arvo
      =/  =response:tool:mcp  !<(response:tool:mcp vase)
        :_  this
        %-  finish
        ?-    -.response
            %error
          %-  wrap-result
          :^  our.bowl  rpc-id
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
          ~
        ::
            %result
          %-  wrap-result
          :^  our.bowl  rpc-id
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
                ::
                    %resource-blob
                  ::  XX parse annotations
                  %-  pairs:enjs:format
                  :~  ['type' s+'resource']
                      :-  'resource'
                      %-  pairs:enjs:format
                      :~  ['uri' s+uri.result]
                          ['mimeType' s+mime.result]
                          ['blob' s+blob.result]
                      ==
                  ==
                ==
              ==
          ~
        ==
      ==
  ::
      [%response %resource %mime eyre-id=@ta rpc-id=@ta ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%khan %arow *]
      :_  this
      %+  send-event
        eyre-id.pole
      ?:  ?=(%.n -.p.sign-arvo)
        (internal:error:rpc (cue-wire-id rpc-id.pole) (of-wain:format (print-tang-to-wain tang.p.p.sign-arvo)) ~)
      !<(json q.p.p.sign-arvo)
    ==
  ::
      [%response %resource %beam eyre-id=@ta rpc-id=@ta uri=@t ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
      ::
        [%clay %writ *]
      =/  [%clay %writ =riot:clay]  sign-arvo
      =/  =beam  (need (parse:beam-uri byk.bowl uri.pole))
      :_  this
      (clay-read our.bowl now.bowl eyre-id.pole (cue-wire-id rpc-id.pole) uri.pole q.beam riot)
    ==
  ::
      [%response %resource %scry %clay care=@tas eyre-id=@ta rpc-id=@ta uri=@t ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%clay %writ *]
      =/  [%clay %writ =riot:clay]  sign-arvo
      ?:  =(%x care.pole)
        ::  scry:// clay paths run /cx/desk/case/...
        =/  =desk  (slav %tas (snag 1 (need (parse:scry-uri uri.pole))))
        :_  this
        (clay-read our.bowl now.bowl eyre-id.pole (cue-wire-id rpc-id.pole) uri.pole desk riot)
      =/  result-text=@t
        ?~  riot
          'Failed to perform Clay scry.'
        ?+  care.pole  'Unsupported Clay scry care.'
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
      :_  this
      %:  send-event
          eyre-id.pole
          %-  wrap-result
          :^  our.bowl  (cue-wire-id rpc-id.pole)
            %-  pairs:enjs:format
            :~  :-  'contents'
                :-  %a
                :~  %-  pairs:enjs:format
                    :~  ['uri' s+uri.pole]
                        ['mimeType' s+'application/json']
                        :-  'text'
                        :-  %s
                        result-text
                    ==
                ==
            ==
          `0
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
        (send-event eyre-id.pole (internal:error:rpc (cue-wire-id rpc-id.pole) 'Unexpected Iris response type' ~))
      ::
          %finished
        ?~  full-file.client-response
          :_  this
          (send-event eyre-id.pole (internal:error:rpc (cue-wire-id rpc-id.pole) 'Empty HTTP response body' ~))
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
            %-  wrap-result
            :^  our.bowl  (cue-wire-id rpc-id.pole)
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
            `0
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
        ~[(fine-read our.bowl now.bowl eyre-id.pole (cue-wire-id rpc-id.pole) uri.pole p.sage q.sage)]
      ?-    task.pole
          %chum
        :_  this
        %+  send-event
          eyre-id.pole
        %:  internal:error:rpc
            (cue-wire-id rpc-id.pole)
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
  ::
  ::  the first watch opens the dojo session; later watchers join it
      [%dojo ses=@ta ~]
    ?>  =(src our):bowl
    ?>  (valid-name:dj ses.pole)
    ?:  (~(has by dojo) ses.pole)
      `this
    =^  evicted=(list @ta)  dojo  (retain:dj dojo)
    :_  this(dojo (~(put by dojo) ses.pole [*sole-share:sole | now.bowl]))
    %+  weld
      ^-  (list card)
      (zing (turn evicted (cury dojo-drop our.bowl)))
    ^-  (list card)
    :~  :*  %pass  /dojo/[ses.pole]  %agent  [our.bowl %dojo]
            %watch  /sole/(scot %p our.bowl)/(dojo-ses:dj ses.pole)
        ==
    ==
  ==
--
