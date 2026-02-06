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
++  send-event
  |=  [eyre-id=@ta =json]
  ^-  (list card)
  %+  give-simple-payload:app:server
    eyre-id
  ^-  simple-payload:http
  :-  :-  200
      :~  ['content-type' 'text/event-stream']
          ['cache-control' 'no-cache']
      ==
    %-  some
    %-  as-octt:mimes:html
    ;:  welp
        "data: "
        (trip (en:json:html json))
        "\0a"
        "\0a"
    ==
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
  =/  defaults
    .^((list path) %ct /(scot %p our.bowl)/mcp-server/(scot %da now.bowl)/fil/default)
  =/  default-tools
    %+  murn
      defaults
    |=  =path
    ^-  (unit tool:mcp)
    ?.  ?=([%fil %default %tools *] path)
      ~
    %-  some
    !<  tool:mcp
    .^(vase %ca (welp /(scot %p our.bowl)/mcp-server/(scot %da now.bowl) path))
  ::
  :-  :~  :*  %pass  /eyre/connect
              %arvo  %e  %connect
              [`/apps/mcp-server/api dap.bowl]
          ==
      ==
  %=  this
    tools      (sy default-tools)
    resources  %-  sy
               ^-  (list resource:mcp)
               %+  welp
                 ::  add resources for default tools
                 %+  turn
                   default-tools
                 |=  =tool:mcp
                 ^-  resource:mcp
                 :*  %-  crip
                     ;:  welp
                         "beam://{<our.bowl>}/mcp-server/=/fil/default/tools/"
                         (trip name.tool)
                         "/hoon"
                     ==
                     (crip "Urbit MCP tool {<name.tool>}")
                     (crip "Source code for Urbit MCP tool {<name.tool>}")
                     `'text/hoon'
                 ==
               ::  add default resources
               %+  murn
                 defaults
               |=  =path
               ^-  (unit resource:mcp)
               ?.  ?=([%fil %default %resources *] path)
                 ~
               %-  some
               !<  resource:mcp
               .^(vase %ca (welp /(scot %p our.bowl)/mcp-server/(scot %da now.bowl) path))
    prompts    %-  sy
               %+  murn
                 defaults
               |=  =path
               ^-  (unit prompt:mcp)
               ?.  ?=([%fil %default %prompts *] path)
                 ~
               %-  some
               !<  prompt:mcp
               .^(vase %ca (welp /(scot %p our.bowl)/mcp-server/(scot %da now.bowl) path))
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
      (send-event eyre-id (rpc-error:ml rpc-internal-error:ml 'Authentication required' ~))
    =/  lin=request-line:server
      (parse-request-line:server url.request.req)
    ::  =/  site=(list @t)  site.lin
    =+  send=(cury response:schooner eyre-id)
    ?+  method.request.req
      [(send [405 ~ [%stock ~]]) this]
    ::
        %'GET'
      =/  connection-json=json
        (pairs:enjs:format ~[['type' s+'connection']])
      :_  this
      (send-event eyre-id connection-json)
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
          (send-event eyre-id (rpc-error:ml rpc-method-not-found:ml 'Method not found' id))
        ::
            [~ [%s %'notifications/initialized']]
          [(send [200 ~ [%none ~]]) this]
        ::
            [~ [%s %'initialize']]
          ::  XX check protocol version?
          ::     would mean we have to declare compat
          :_  this
          %:  send-event
              eyre-id
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
          ==
        ::
            [~ [%s %'tools/list']]
          :_  this
          (send-event eyre-id (rpc-result:ml (mcp-tools-to-json:ml tools) id))
        ::
            [~ [%s %'resources/list']]
          :_  this
          (send-event eyre-id (rpc-result:ml (mcp-resources-to-json:ml resources) id))
        ::
            [~ [%s %'prompts/list']]
          :_  this
          (send-event eyre-id (rpc-result:ml (mcp-prompts-to-json:ml prompts) id))
        ::
            [~ [%s %'resources/read']]
          =/  uri=(unit @t)
            (fall (mole |.((~(deg jo:ju jon) /params/uri so:dejs:format))) ~)
          ?~  uri
            :_  this
            (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Missing or invalid resource URI' id))
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
                %:  rpc-error:ml
                    rpc-invalid-request:ml
                    (crip "Scheme not supported for URI {<u.uri>}")
                    id
                ==
            ==
          ::
              %'beam'
            =>  |%
                ++  parse-beam-uri
                  |=  =cord
                  ^-  (unit beam)
                  ::  we don't need to validate the scheme here,
                  ::  but a canonical beam:// URI parser should
                  =/  stub-count
                    %+  roll
                      (trip cord)
                    |=  [a=@tD b=@ud]
                    ?:  =(a '=')
                      +(b)
                    b
                  ?.  (gte 3 stub-count)
                    ::  fail; a beam:// can have no more than three stubs
                    ~
                  ?:  =(0 stub-count)
                    ::  skip dereferencing
                    (de-beam (stab cord))
                  |^  %.  %+  turn
                            %+  split
                              "/"
                            ::  normalise e.g. /===/ to /=/=/=/
                            ::  works for any combination of values and =
                            %^    replace
                                "=="
                              "=/="
                            ::  remove beam:/, leaving / prefix on the tape
                            (oust [0 7] (trip cord))
                          crip
                      ::  replace = path segments with default values
                      |=  =(pole @t)
                      ^-  (unit beam)
                      ?+  pole  ~
                          [her=@t dek=@t cas=@t und=*]
                        %-  de-beam
                        %-  stab
                        %-  crip
                        ;:  welp
                            "/"
                            ?.  =('=' her.pole)  (trip her.pole)  "{<our.bowl>}"
                            "/"
                            ::  XX don't hard-code %base and do *desk?
                            ?.  =('=' dek.pole)  (trip dek.pole)  "base"
                            "/"
                            ?.  =('=' cas.pole)  (trip cas.pole)  "{<now.bowl>}"
                            "/"
                            (zing (turn (join '/' und.pole) trip))
                        ==
                      ==
                  ::
                  :: ~lagrev-nocfep/yard/~2026.2.5/lib/string/hoon
                  ++  replace
                    |=  [bit=tape bot=tape =tape]
                    ^-  ^tape
                    |-
                    =/  off  (find bit tape)
                    ?~  off  tape
                    =/  clr  (oust [(need off) (lent bit)] tape)
                    $(tape :(weld (scag (need off) clr) bot (slag (need off) clr)))
                  ++  split
                    |=  [sep=tape =tape]
                    ^-  (list ^tape)
                    =|  res=(list ^tape)
                    |-
                    ?~  tape  (flop res)
                    =/  off  (find sep tape)
                    ?~  off  (flop [`^tape`tape `(list ^tape)`res])
                    %=  $
                      res   [(scag `@ud`(need off) `^tape`tape) res]
                      tape  (slag +(`@ud`(need off)) `^tape`tape)
                    ==
                  --
                --
            =/  parsed-beam=(unit beam)
              (parse-beam-uri u.uri)
            ?~  parsed-beam
              :_  this
              %:  send-event
                  eyre-id
                  %:  rpc-error:ml
                      rpc-invalid-request:ml
                      (crip "Invalid beam {<u.uri>}")
                      id
                  ==
              ==
            =/  request-id=(unit @ud)
              (bind id ni:dejs:format)
            ?~  request-id
              :_  this
              (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Missing or invalid JSON RPC request ID' ~))
            :_  this
            :~  :*  %pass  /thread-result/[eyre-id]/(scot %ud u.request-id)
                    %arvo  %k
                    %fard  q.byk.bowl
                    %read-beam  %beam  !>(parsed-beam)
                ==
            ==
          ::
              ?(%'http' %'https')
            =/  request-id=(unit @ud)
              (bind id ni:dejs:format)
            ?~  request-id
              :_  this
              (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Missing or invalid JSON RPC request ID' ~))
            :_  this
            :~  :*  %pass
                    /resource/[eyre-id]/[(scot %ud u.request-id)]/(scot %t u.uri)
                    %arvo
                    %i
                    [%request [%'GET' u.uri ~ ~] *outbound-config:iris]
                ==
            ==
          ==
        ::
            [~ [%s %'prompts/get']]
          =/  prompt-name=(unit @t)
            (fall (mole |.((~(deg jo:ju jon) /params/name so:dejs:format))) ~)
          ?~  prompt-name
            :_  this
            (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Missing or invalid prompt name' id))
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
            (send-event eyre-id (rpc-error:ml rpc-method-not-found:ml (crip "Prompt {<u.prompt-name>} not found") id))
          ?:  (gth 1 (lent prompt-results))
            :_  this
            (send-event eyre-id (rpc-error:ml rpc-internal-error:ml (crip "Multiple {<u.prompt-name>} prompts found") id))
          =/  =prompt:mcp  i.prompt-results
          :_  this
          %:  send-event
              eyre-id
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
          ==
        ::
            [~ [%s %'tools/call']]
          =/  rpc-id=(unit @ud)  (bind id ni:dejs:format)
          ?~  rpc-id
            :_  this
            (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Missing JSON RPC request ID' id))
          :_  this
          =/  tool-name=(unit @t)  
            (fall (mole |.((~(deg jo:ju jon) /params/name so:dejs:format))) ~)
          ?~  tool-name
            (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Missing or invalid tool name' id))
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
            (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml (crip "Tool {<u.tool-name>} not found") id))
          ?:  (gth 1 (lent tool-results))
            (send-event eyre-id (rpc-error:ml rpc-internal-error:ml (crip "Multiple {<u.tool-name>} tools found") id))
          =/  arguments=(unit json)  (~(get jo:ju jon) /params/arguments)
          ?~  arguments
            (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Missing arguments' id))
          =/  args-map=(unit (map @t json))
            ?:  ?=([%o *] u.arguments)
              `p.u.arguments
            ~
          ?~  args-map
            (send-event eyre-id (rpc-error:ml rpc-invalid-params:ml 'Invalid arguments' id))
          ^-  (list card)
          :~  :*  %pass  /thread-result/[eyre-id]/(scot %ud u.rpc-id)
                  %arvo  %k
                  %lard  q.byk.bowl
                  (thread-builder.i.tool-results u.args-map)
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
        (send-event eyre-id.pole (rpc-error:ml rpc-internal-error:ml (crip (print-tang-to-wain tang.p.p.sign-arvo)) `[%n id.pole]))
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
          =/  type-text=(unit @t)
            (fall (mole |.((~(deg jo:ju tool-result) /type so:dejs:format))) ~)
          =/  content-text=(unit @t)
            (fall (mole |.((~(deg jo:ju tool-result) /text so:dejs:format))) ~)
          ?~  type-text
            ~
          ?~  content-text
            ~
          ?.  =(u.type-text 'text')
            ~
          content-text
        ==
      ?~  text-content
        :_  this
        (send-event eyre-id.pole (rpc-error:ml rpc-internal-error:ml 'Invalid tool response format' `[%n id.pole]))
      :_  this
      (send-event eyre-id.pole (mcp-text-result:ml u.text-content `[%n id.pole]))
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
        (send-event eyre-id.pole (rpc-error:ml rpc-internal-error:ml 'Unexpected Iris response type' `[%n id.pole]))
      ::
          %finished
        ?~  full-file.client-response
          :_  this
          (send-event eyre-id.pole (rpc-error:ml rpc-internal-error:ml 'Empty HTTP response body' `[%n id.pole]))
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
  ==
++  on-watch
  |=  =(pole knot)
  ^-  (quip card _this)
  ?+    pole  (on-watch:def `path`pole)
      [%http-response eyre-id=@ta ~]
    `this
  ==
--
