/-  mcp
/+  dbug, verb, server, schooner, default-agent,
    ju=json-utils, ml=mcp
|%
+$  card  card:agent:gall
+$  versioned-state
  $:  state-0
  ==
+$  state-0
  $:  %0
      tools=(set tool:mcp)
      resources=(set resource:mcp)
      prompts=(set prompt:mcp)
  ==
--
%-  agent:dbug
^-  agent:gall
=|  state-0
=*  state  -
%+  verb  &
|_  =bowl:gall
+*  this   .
    def    ~(. (default-agent this %|) bowl)
::
++  on-fail   on-fail:def
++  on-peek   on-peek:def
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  ?-    -.old
      %0
    `this(state old)
  ==
::
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-init
  ^-  (quip card _this)
  :-  :~  :*  %pass  /eyre/connect
              %arvo  %e  %connect
              [`/apps/mcp-server/api dap.bowl]
          ==
      ==
  %=  this
    tools      (sy tools:defaults:ml)
    resources  (sy resources:defaults:ml)
    prompts    (sy prompts:defaults:ml)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ::  XX would be nice to use clan so LLMs could use
  ::     their own moon IDs; Gall agents can discriminate
  ::     between our.bowl or ships in our clan
  ::  ?>  =(src.bowl our.bowl)
  |^  ?+    mark  (on-poke:def mark vase)
          %handle-http-request
        (handle-req !<([@ta inbound-request:eyre] vase))
      ==
  ++  handle-req
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  lin=request-line:server
      (parse-request-line:server url.request.req)
    ::  =/  site=(list @t)  site.lin
    =+  send=(cury response:schooner eyre-id)
    ?+  method.request.req
      [(send [405 ~ [%stock ~]]) this]
    ::
        %'POST'
      =/  content-type=(unit @t)
        (get-header:http 'content-type' header-list.request.req)
      ?+  content-type
        [(send [415 ~ [%stock ~]]) this]
      ::
          [~ %'application/json']
        =/  parsed=(unit json)
          (de:json:html q:(need body.request.req))
        ?~  parsed
          [(send [400 ~ [%stock ~]]) this]
        %.  u.parsed
        |=  jon=json
        =/  id=(unit json)      (~(get jo:ju jon) /id)
        =/  method=(unit json)  (~(get jo:ju jon) /method)
        ?+  method
          :_  this
          (send 405 ~ %json (rpc-error:ml rpc-method-not-found:ml 'Method not found' id))
        ::
            [~ [%s %'notifications/initialized']]
          [(send [200 ~ [%none ~]]) this]
        ::
            [~ [%s %'initialize']]
          ::  XX check protocol version?
          ::     would mean we have to declare compat
          :_  this
          %-  send
          :^    200
              ~
            %json
          ::  *json
          %-  pairs:enjs:format
          %+  welp
            ?~(id ~ ['id' u.id]~)
          :~  ['jsonrpc' s+'2.0']
              :-  'result'
              %-  pairs:enjs:format
              :~  ['protocolVersion' s+'2024-11-05']
                  :-  'capabilities'
                  %-  pairs:enjs:format
                  :~  :-  'tools'
                      ::  XX change to %.y once we support listChanged notifs
                      (pairs:enjs:format ~[['listChanged' b+%.n]])
                  ==
                  :-  'serverInfo'
                  %-  pairs:enjs:format
                  ::  XX specify real or fake in the server name
                  :~  ['name' s+(crip "{<our.bowl>} urbit mcp server")]
                      ['version' s+'1.0.0']
                  ==
              ==
          ==
        ::
            [~ [%s %'tools/list']]
          :_  this
          %^    send
              200
            ~
          :-  %json
          ::  XX put fake/dev ship @p in the server title
          ::  XX use an actual version number
          (mcp-tools-list:ml id)
        ::
            [~ [%s %'tools/call']]
          ?<  ?=(~ id)
          ?>  ?=([%n @ta] u.id)
          :_  this
          =/  tool-name=(unit json)
            (~(get jo:ju jon) /params/name)
          ?~  tool-name
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Missing tool name' id))
          ?.  ?=([%s *] u.tool-name)
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Invalid tool name' id))
          =/  tool-results
            %+  murn
              ~(tap in tools)
            ::  XX placeholder name
            |=  foo=tool:mcp
            ^-  (unit tool:mcp)
            ?.  =(name.foo p.u.tool-name)
              ~
            `foo
          ?~  tool-results
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml (crip "Tool {<tool-name>} not found") id))
          ?:  (gth 1 (lent tool-results))
            (send 200 ~ %json (rpc-error:ml rpc-internal-error:ml (crip "Multiple {<tool-name>} tools found") id))
          =/  arguments=(unit json)
            (~(get jo:ju jon) /params/arguments)
          ?~  arguments
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Missing arguments' id))
          ?.  ?=([%o *] u.arguments)
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Invalid arguments' id))
          ^-  (list card)
          :~  :*  %pass  /thread-result/[eyre-id]/[p.u.id]
                  %arvo  %k
                  %lard  q.byk.bowl
                  (thread-builder.i.tool-results p.u.arguments)
              ==
          ==
        ==
      ==
    ==
  --
++  on-arvo
  |=  [=(pole knot) =sign-arvo]
  ^-  (quip card _this)
  ?+  pole
    ~_  leaf/"mcp-server: unrecognized wire {<`path`pole>}"
    !!
  ::
      [%eyre %connect ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ?:  accepted.sign-arvo
      `this
    %-  (slog leaf/"mcp-server: failed to bind {<dap.bowl>} to /apps/mcp-server/api" ~)
    `this
  ::
      [%thread-result eyre-id=@ta id=@ud ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%khan %arow *]
      =+  send=(cury response:schooner eyre-id.pole)
      ?.  -.p.sign-arvo
        :_  this
        %^    send
            500
          ~
        :-  %json
        (rpc-error:ml rpc-internal-error:ml (crip "{<p.p.sign-arvo>}") `[%n id.pole])
      ?>  ?=([%khan %arow %.y %noun *] sign-arvo)
      =/  [%khan %arow %.y %noun =vase]  sign-arvo
      =/  tool-result=json  !<(json vase)
      =/  text-content=(unit @t)
        ?.  ?=([%s *] tool-result)
          ~
        `p.tool-result
      ?~  text-content
        :_  this
        %^    send
            500
          ~
        :-  %json
        (rpc-error:ml rpc-internal-error:ml 'Invalid tool response format' `[%n id.pole])
      [(send [200 ~ [%json (mcp-text-result:ml u.text-content `[%n id.pole])]]) this]
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
