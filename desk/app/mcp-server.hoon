/-  mcp
/+  dbug, verb, server, default-agent,
    jut=json-utils, ml=mcp
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
      ==
    %-  some
    %-  as-octt:mimes:html
    (trip (en:json:html json))
::
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
      state-1
  ==
+$  state-0
  $:  %0
      tools=(set tool:mcp)
      prompts=(set prompt:mcp)
      resources=(set resource:mcp)
  ==
+$  state-1
  $:  %1
      tools=(set tool:mcp)
      prompts=(set prompt:mcp)
      resources=(set resource:mcp)
      auth-token=@t               ::  auto-generated x-api-key for /mcp
  ==
::  extract x-api-key header value (case-insensitive)
++  get-api-key
  |=  headers=(list [key=@t value=@t])
  ^-  (unit @t)
  |-  ^-  (unit @t)
  ?~  headers  ~
  ?:  =((cass (trip key.i.headers)) "x-api-key")  `value.i.headers
  $(headers t.headers)
--
%-  agent:dbug
^-  agent:gall
=|  state-1
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
  =/  new=state-1
    ?-    -.old
        %1  old
        %0
      :*  %1
          tools.old
          prompts.old
          resources.old
          ''                          ::  await mcp-proxy poke
      ==
    ==
  :-  ~
  this(state new)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  :*  %pass  /eyre/connect
          %arvo  %e  %connect
          [`/mcp dap.bowl]
      ==
      :*  %pass  ~
          %arvo  %k
          %fard  q.byk.bowl
          %install-features
          :-  %noun
          !>  ^-  (list beam)
          %+  turn
            .^  (list path)
                %ct
                /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)/fil/default/mcp
            ==
          |=  pax=path
          ^-  beam
          %-  need
          %-  de-beam
          %+  welp
            /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)
          pax
  ==  ==
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
          %set-auth-token
        ::  poked by mcp-proxy to keep keys in sync
        ?>  =(src our):bowl
        =.  auth-token  !<(@t vase)
        `this
      ::
          ?(%add-tool %add-prompt %add-resource)
        ?>  =(src our):bowl
        ::  XX send listChanged notification
        :-  ~
        ?-  mark
          %add-tool
            this(tools (~(put in tools) !<(tool:mcp vase)))
          %add-prompt
            this(prompts (~(put in prompts) !<(prompt:mcp vase)))
          %add-resource
            this(resources (~(put in resources) !<(resource:mcp vase)))
        ==
      ==
  ++  handle-req
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    ::  auth: require x-api-key header matching auth-token
    ?:  =('' auth-token)
      :_  this
      (send-event eyre-id (internal:error:rpc:ml 'Server not configured' ~))
    =/  supplied=(unit @t)  (get-api-key header-list.request.req)
    ?~  supplied
      :_  this
      (send-event eyre-id (internal:error:rpc:ml 'Missing x-api-key header' ~))
    ?.  =(u.supplied auth-token)
      :_  this
      (send-event eyre-id (internal:error:rpc:ml 'Invalid x-api-key' ~))
    ?+  method.request.req
      [(simple-response eyre-id 405 ~) this]
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
        [(simple-response eyre-id 415 ~) this]
      ::
          [~ %'application/json']
        =/  parsed=(unit json)
          (de:json:html q:(need body.request.req))
        ?~  parsed
          [(simple-response eyre-id 400 ~) this]
        %.  u.parsed
        |=  jon=json
        =/  id=(unit json)      (~(get jo:jut jon) /id)
        =/  method=(unit json)  (~(get jo:jut jon) /method)
        ?+  method
          :_  this
          (send-event eyre-id (method:error:rpc:ml 'Method not found' id))
        ::
            [~ [%s %'notifications/initialized']]
          [(simple-response eyre-id 200 ~) this]
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
          ==  ==  ==  ==
        ::
            [~ [%s %'tools/list']]
          :_  this
          (send-event eyre-id (result:rpc:ml (mcp-tools-to-json:ml tools) id))
        ::
            [~ [%s %'resources/list']]
          :_  this
          (send-event eyre-id (result:rpc:ml (mcp-resources-to-json:ml resources) id))
        ::
            [~ [%s %'prompts/list']]
          :_  this
          (send-event eyre-id (result:rpc:ml (mcp-prompts-to-json:ml prompts) id))
        ::
            [~ [%s %'resources/read']]
          =/  uri=(unit @t)
            (~(deg jo:jut jon) /params/uri so:dejs:format)
          ?~  uri
            :_  this
            (send-event eyre-id (params:error:rpc:ml 'Missing or invalid resource URI' id))
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
                %:  request:error:rpc:ml
                    (crip "Scheme not supported for URI {<u.uri>}")
                    id
            ==  ==
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
                  ::
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
                  %:  request:error:rpc:ml
                      (crip "Invalid beam {<u.uri>}")
                      id
              ==  ==
            =/  request-id=(unit @ud)
              (bind id ni:dejs:format)
            ?~  request-id
              :_  this
              (send-event eyre-id (params:error:rpc:ml 'Missing or invalid JSON RPC request ID' ~))
            :_  this
            :~  :*  %pass  /res/resource/[eyre-id]/(scot %ud u.request-id)
                    %arvo  %k
                    %fard  q.byk.bowl
                    %read-beam  %beam  !>(parsed-beam)
            ==  ==
          ::
              ?(%'http' %'https')
            =/  request-id=(unit @ud)
              (bind id ni:dejs:format)
            ?~  request-id
              :_  this
              (send-event eyre-id (params:error:rpc:ml 'Missing or invalid JSON RPC request ID' ~))
            :_  this
            :~  :*  %pass
                    /res/resource/[eyre-id]/(scot %ud u.request-id)/[u.uri]
                    %arvo
                    %i
                    [%request [%'GET' u.uri ~ ~] *outbound-config:iris]
            ==  ==
          ==
        ::
            [~ [%s %'prompts/get']]
          =/  prompt-name=(unit @t)
            (~(deg jo:jut jon) /params/name so:dejs:format)
          ?~  prompt-name
            :_  this
            (send-event eyre-id (params:error:rpc:ml 'Missing or invalid prompt name' id))
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
            (send-event eyre-id (method:error:rpc:ml (crip "Prompt {<u.prompt-name>} not found") id))
          ?:  (gth 1 (lent prompt-results))
            :_  this
            (send-event eyre-id (internal:error:rpc:ml (crip "Multiple {<u.prompt-name>} prompts found") id))
          =/  =prompt:mcp  i.prompt-results
          =/  prompt-args=(map name:argument:prompt:mcp @t)
            %+  fall
              (~(deg jo:jut jon) /params/arguments (om so):dejs:format)
            *(map name:argument:prompt:mcp @t)
          :_  this
          %:  send-event
              eyre-id
              %-  result:rpc:ml
              :-  %-  pairs:enjs:format
                  :~  ['description' s+desc.prompt]
                      :-  'messages'
                      %-  prompt-messages-to-json:ml
                      (messages-builder.prompt prompt-args)
                  ==
              id
          ==
        ::
            [~ [%s %'tools/call']]
          =/  rpc-id=(unit @ud)  (bind id ni:dejs:format)
          ?~  rpc-id
            :_  this
            (send-event eyre-id (params:error:rpc:ml 'Missing JSON RPC request ID' id))
          :_  this
          =/  tool-name=(unit @t)
            (~(deg jo:jut jon) /params/name so:dejs:format)
          ?~  tool-name
            (send-event eyre-id (params:error:rpc:ml 'Missing or invalid tool name' id))
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
            (send-event eyre-id (params:error:rpc:ml (crip "Tool {<u.tool-name>} not found") id))
          ?:  (gth 1 (lent tool-results))
            (send-event eyre-id (internal:error:rpc:ml (crip "Multiple {<u.tool-name>} tools found") id))
          =/  arguments=(unit json)  (~(get jo:jut jon) /params/arguments)
          ?~  arguments
            (send-event eyre-id (params:error:rpc:ml 'Missing arguments' id))
          =/  args-map=(unit (map @t json))
            ?:  ?=([%o *] u.arguments)
              `p.u.arguments
            ~
          ?~  args-map
            (send-event eyre-id (params:error:rpc:ml 'Invalid arguments' id))
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
          :~  :*  %pass  /res/tool/[eyre-id]/(scot %ud u.rpc-id)
                  %arvo  %k
                  %lard  q.byk.bowl
                  %-  thread-builder.i.tool-results
                  (~(run by u.args-map) parse-arg)
          ==  ==
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
    ::
    ::  .^(@t %gx /=mcp-server=/auth-token/noun)
    ::  read the auto-generated auth token (for internal use)
    [%x %auth-token ~]
      ``noun+!>(auth-token)
  ==
++  on-arvo
  |=  [=(pole knot) =sign-arvo]
  ^-  (quip card _this)
  ?+  pole
    `this
  ::
      [%eyre %connect ~]
    ?>  ?=([%eyre %bound *] sign-arvo)
    ?:  accepted.sign-arvo
      `this
    %-  (slog leaf/"mcp: failed to bind {<dap.bowl>} to /mcp" ~)
    `this
  ::
      [%res feat=@ta eyre-id=@ta rpc-id=@ta und=*]
    ?+  sign-arvo
      (on-arvo:def pole sign-arvo)
    ::
        [%khan %arow *]
      ?:  ?=(%.n -.p.sign-arvo)
        :_  this
        %+  send-event
          eyre-id.pole
        (internal:error:rpc:ml (crip (print-tang-to-wain tang.p.p.sign-arvo)) `[%n rpc-id.pole])
      ?>  ?=([%khan %arow %.y %noun *] sign-arvo)
      =/  [%khan %arow %.y %noun =vase]  sign-arvo
      =/  result=json  !<(json vase)
      ?+  feat.pole
        :_  this
        %+  send-event
          eyre-id.pole
        (internal:error:rpc:ml 'Unknown response type' `[%n rpc-id.pole])
      ::
          %tool
        =/  response-text=(unit @t)
          ?+  result
            ~
          ::
              [%s *]
            `p.result
          ::
              [%o *]
            =/  typ=(unit @t)  (~(deg jo:jut result) /type so:dejs:format)
            =/  txt=(unit @t)  (~(deg jo:jut result) /text so:dejs:format)
            ?~  typ
              ~
            ?~  txt
              ~
            ?.  =(u.typ 'text')
              ~
            txt
          ==
        ?~  response-text
          :_  this
          %+  send-event
            eyre-id.pole
          (internal:error:rpc:ml 'Invalid tool response format' `[%n rpc-id.pole])
        :_  this
        %+  send-event
          eyre-id.pole
        (mcp-text-result:ml u.response-text `[%n rpc-id.pole])
      ::
          %resource
        =/  uri=(unit @t)  (~(deg jo:jut result) /uri so:dejs:format)
        =/  mym=(unit @t)  (~(deg jo:jut result) /mime-type so:dejs:format)
        =/  txt=(unit @t)  (~(deg jo:jut result) /text so:dejs:format)
        ?~  uri
          :_  this
          (send-event eyre-id.pole (internal:error:rpc:ml 'Missing uri in resource response' `[%n rpc-id.pole]))
        ?~  mym
          :_  this
          (send-event eyre-id.pole (internal:error:rpc:ml 'Missing mimeType in resource response' `[%n rpc-id.pole]))
        ?~  txt
          :_  this
          (send-event eyre-id.pole (internal:error:rpc:ml 'Missing text in resource response' `[%n rpc-id.pole]))
        :_  this
        %:  send-event
            eyre-id.pole
            %-  result:rpc:ml
            :-  %-  pairs:enjs:format
                :~  :-  'contents'
                    :-  %a
                    :~  %-  pairs:enjs:format
                        :~  ['uri' s+u.uri]
                            ['mimeType' s+u.mym]
                            ['text' s+u.txt]
                        ==
                    ==
                ==
            `[%n rpc-id.pole]
        ==
      ==
    ::
        [%iris %http-response *]
      ?<  ?=(~ und.pole)
      ?>  ?=([@ta ~] und.pole)
      =*  uri  -.und.pole
      =/  =client-response:iris  client-response.sign-arvo
      ?+  -.client-response
        :_  this
        (send-event eyre-id.pole (internal:error:rpc:ml 'Unexpected Iris response type' `[%n rpc-id.pole]))
      ::
          %finished
        ?~  full-file.client-response
          :_  this
          (send-event eyre-id.pole (internal:error:rpc:ml 'Empty HTTP response body' `[%n rpc-id.pole]))
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
            %-  result:rpc:ml
            :-  %-  pairs:enjs:format
                :~  :-  'contents'
                    :-  %a
                    :~  %-  pairs:enjs:format
                        :~  ['uri' s+uri]
                            ['mimeType' s+content-type]
                            ['text' s+body-text]
                        ==
                    ==
                ==
            `[%n rpc-id.pole]
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
