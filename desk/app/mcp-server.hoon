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
++  on-load   on-load:def
++  on-peek   on-peek:def
++  on-save   on-save:def
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
  ++  rpc-method-not-found
    |=  eyre-id=@ta
    ^-  (list card)
    =+  send=(cury response:schooner eyre-id)
    ::  XX proper error code
    %-  send
    :*  405
        ~
        :-  %application-json
        *cord
  ::      %:  rpc-error:ml
  ::          rpc-method-not-found:ml
  ::          'Method not found'
  ::          eyre-id
  ::      ==
    ==
    ++  handle-req
      |=  [eyre-id=@ta req=inbound-request:eyre]
      ^-  (quip card _this)
      =/  lin=request-line:server
        (parse-request-line:server url.request.req)
      ::  =/  site=(list @t)  site.lin
      =+  send=(cury response:schooner eyre-id)
      ?+      method.request.req
            ::  XX better error
            [(send [405 ~ [%stock ~]]) this]
          %'POST'
        =/  content-type=(unit @t)
          (get-header:http 'content-type' header-list.request.req)
        ::  XX better error
        ?+    content-type  [(send [405 ~ [%stock ~]]) this]
            [~ %'application/json']
          =/  parsed=(unit json)
            (de:json:html q:(need body.request.req))
          ?~  parsed
            ::  XX better error
            [(send [405 ~ [%stock ~]]) this]
          %.  u.parsed
          |=  jon=json
          =/  id=(unit json)      (~(get jo:ju jon) /id)
          =/  method=(unit json)  (~(get jo:ju jon) /method)
          ?+    method  [(rpc-method-not-found eyre-id) this]
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
              [~ [%s %'notifications/initialized']]
            :_  this
            (send [200 ~ [%json *json]])
          ::
              [~ [%s %'tools/list']]
            :_  this
            %:  send
                200
                ~
                %json
                ::  XX put fake/dev ship @p in the server title
                ::  XX use an actual version number
                %:  mcp-tools-list:ml
                    (crip "{<our.bowl>} urbit mcp server")
                    '1.0.0'
                    id
                ==
            ==
          ::
              [~ [%s %'tools/call']]
            :_  this
            (send [200 ~ [%json *json]])
          ==
        ==
      ==
  --
++  on-arvo
  |=  [=(pole knot) =sign-arvo]
  ^-  (quip card _this)
  ?+    pole
      ~_  leaf/"mcp-server: unrecognized wire {<`path`pole>}"
      !!
      [%eyre %connect ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ?:  accepted.sign-arvo
      `this
    %-  (slog leaf/"mcp-server: failed to bind {<dap.bowl>} to /apps/mcp-server/api" ~)
    `this
  ==
++  on-watch
  |=  =(pole knot)
  ^-  (quip card _this)
  ?+    pole  (on-watch:def `path`pole)
      [%http-response eyre-id=@ta ~]
    `this
  ==
--
