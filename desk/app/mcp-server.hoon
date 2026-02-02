/-  mcp
/+  dbug, verb, server, schooner, default-agent,
    ju=json-utils, ml=mcp
|%
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
  ?-    -.old
      %0
    `this(state old)
  ==
::
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
  |^  ?+  mark
        (on-poke:def mark vase)
      ::
          %handle-http-request
        (handle-req !<([@ta inbound-request:eyre] vase))
      ::
          %add-mcp-tool
        ?>  =(src our):bowl
        =/  =tool:mcp  !<(tool:mcp vase)
        ::  XX send listChanged notification
        ::  XX add resource to scry the contents of this tool?
        :-  ~
        %=  this
          tools  (~(put in tools) tool)
        ==
      ==
  ++  handle-req
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    ::  Check authentication first
    ?.  authenticated.req
      =+  send=(cury response:schooner eyre-id)
      :_  this
      %^    send
          401
        ~
      :-  %json
      (rpc-error:ml rpc-internal-error:ml 'Authentication required' ~)
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
                      :-  'resources'
                      (pairs:enjs:format ~[['subscribe' b+%.n] ['listChanged' b+%.n]])
                      :-  'prompts'
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
          (rpc-result:ml (mcp-tools-to-json:ml tools) id)
        ::
            [~ [%s %'resources/list']]
          :_  this
          %^    send
              200
            ~
          :-  %json
          (rpc-result:ml (mcp-resources-to-json:ml resources) id)
        ::
            [~ [%s %'prompts/list']]
          :_  this
          %^    send
              200
            ~
          :-  %json
          (rpc-result:ml (mcp-prompts-to-json:ml prompts) id)
        ::
            [~ [%s %'resources/read']]
          =/  uri=(unit json)  (~(get jo:ju jon) /params/uri)
          ?~  uri
            :_  this
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Missing resource URI' id))
          ?.  ?=([%s *] u.uri)
            :_  this
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Invalid resource URI' id))
          =/  uri-string=@t  p.u.uri
          =/  uri-tape=tape  (trip uri-string)
          ::  fetch http / https resources with iris
          ?:  ?|  =("http://" (scag 7 uri-tape))
                  =("https://" (scag 8 uri-tape))
              ==
            ?~  id
              :_  this
              (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Missing JSON RPC request ID' ~))
            ?>  ?=([%n *] u.id)
            :_  this
            :~  :*  %pass  /resource/[eyre-id]/[p.u.id]/(scot %t p.u.uri)
                    %arvo  %i
                    [%request [%'GET' uri-string ~ ~] *outbound-config:iris]
                ==
            ==
          ::  XX just error on all other resources for now
          ::     different URI schemes require different handlers
          :_  this
          %^    send
              200
            ~
          :-  %json
          %:  rpc-error:ml
              rpc-method-not-found:ml
              (crip "Resource {<uri-string>} not found")
              id
          ==
        ::
            [~ [%s %'prompts/get']]
          =/  prompt-name=(unit json)  (~(get jo:ju jon) /params/name)
          ?~  prompt-name
            :_  this
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Missing prompt name' id))
          ?.  ?=([%s *] u.prompt-name)
            :_  this
            (send 200 ~ %json (rpc-error:ml rpc-invalid-params:ml 'Invalid prompt name' id))
          =/  prompt-results
            %+  murn
              ~(tap in prompts)
            |=  =prompt:mcp
            ^-  (unit prompt:mcp)
            ?.  =(name.prompt p.u.prompt-name)
              ~
            `prompt
          ?~  prompt-results
            :_  this
            (send 200 ~ %json (rpc-error:ml rpc-method-not-found:ml (crip "Prompt {<p.u.prompt-name>} not found") id))
          ?:  (gth 1 (lent prompt-results))
            :_  this
            (send 200 ~ %json (rpc-error:ml rpc-internal-error:ml (crip "Multiple {<p.u.prompt-name>} prompts found") id))
          =/  =prompt:mcp  i.prompt-results
          :_  this
          %^    send
              200
            ~
          :-  %json
          %-  rpc-result:ml
          :-  %-  pairs:enjs:format
              :~  ['name' s+name.prompt]
                  ['title' s+title.prompt]
                  ['description' s+desc.prompt]
                  :-  'arguments'
                  :-  %a
                  %+  turn
                    arguments.prompt
                  |=  arg=prompt-argument:mcp
                  ^-  json
                  %-  pairs:enjs:format
                  %+  welp
                    :~  ['name' s+name.arg]
                        ['description' s+desc.arg]
                        ['required' b+required.arg]
                    ==
                  ?~  parameter-type.arg  ~
                  :~  ['type' s+(param-type-to-json:ml u.parameter-type.arg)]
                  ==
              ==
          id
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
++  on-peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+  pole  (on-peek:def `path`pole)
    ::
    ::  .^(json %gx /=mcp-server=/tools/json)
    ::  read tool definitions
    [%x %tools ~]
      ``json+!>((mcp-tools-to-json:ml tools))
    ::
    ::  .^(json %gx /=mcp-server=/resources/json)
    ::  read resource definitions
    [%x %resources ~]
      ``json+!>((mcp-resources-to-json:ml resources))
    ::
    ::  .^(json %gx /=mcp-server=/prompts/json)
    ::  read prompt definitions
    [%x %prompts ~]
      ``json+!>((mcp-prompts-to-json:ml prompts))
  ==
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
      ?:  ?=(%.n -.p.sign-arvo)
        :_  this
        %^    send
            500
          ~
        :-  %json
        (rpc-error:ml rpc-internal-error:ml (crip (print-tang-to-wain tang.p.p.sign-arvo)) `[%n id.pole])
      ?>  ?=([%khan %arow %.y %noun *] sign-arvo)
      =/  [%khan %arow %.y %noun =vase]  sign-arvo
      =/  tool-result=json  !<(json vase)
      =/  text-content=(unit @t)
        ?+  tool-result
          ~
        ::
            [%s *]
          `p.tool-result
        ::
            [%o *]
          =/  type-field=(unit json)  (~(get by p.tool-result) 'type')
          =/  text-field=(unit json)  (~(get by p.tool-result) 'text')
          ?~  type-field  ~
          ?~  text-field  ~
          ?.  ?=([%s %'text'] u.type-field)  ~
          ?.  ?=([%s *] u.text-field)  ~
          `p.u.text-field
        ==
      ?~  text-content
        :_  this
        %^    send
            500
          ~
        :-  %json
        (rpc-error:ml rpc-internal-error:ml 'Invalid tool response format' `[%n id.pole])
      [(send [200 ~ [%json (mcp-text-result:ml u.text-content `[%n id.pole])]]) this]
    ==
  ::
      [%resource eyre-id=@ta id=@ud uri=@ta ~]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%iris %http-response *]
      =+  send=(cury response:schooner eyre-id.pole)
      =/  =client-response:iris  client-response.sign-arvo
      ?+  -.client-response
        :_  this
        %^    send
            500
          ~
        :-  %json
        (rpc-error:ml rpc-internal-error:ml 'Unexpected Iris response type' `[%n id.pole])
      ::
          %finished
        ?~  full-file.client-response
          :_  this
          %^    send
              500
            ~
          :-  %json
          (rpc-error:ml rpc-internal-error:ml 'Empty HTTP response body' `[%n id.pole])
        =/  =response-header:http  response-header.client-response
        =/  content-type=@t
          ?~  content-type-header=(get-header:http 'content-type' headers.response-header)
            'text/plain'
          u.content-type-header
        =/  body-text=@t
          (rap 3 ~[q.data.u.full-file.client-response])
        :_  this
        %^    send
            200
          ~
        :-  %json
        %-  rpc-result:ml
        :-  %-  pairs:enjs:format
            :~  :-  'contents'
                :-  %a
                :~  %-  pairs:enjs:format
                    :~  ['uri' s+(@t (slav %t uri.pole))]
                        ['mimeType' s+content-type]
                        ['text' s+body-text]
                    ==
                ==
            ==
        `[%n id.pole]
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
