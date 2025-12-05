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
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
++  on-load   on-load:def
++  on-peek   on-peek:def
++  on-save   on-save:def
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-watch  on-watch:def
++  on-init
  ^-  (quip card _this)
  ::  XX bind /apps/mcp-server/api endpoint in Eyre
  ::  XX populate state with defaults
  `this
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
            %:  send
                200
                ~
                :-  %application-json
                ::  XX remove server-name and version args?
                ::  XX pass in mcp stuff from agent state
                ::  (mcp-initialize:ml 'mcp-server' '1.0.0' eyre-id)
                *cord
            ==
          ::
              [~ [%s %'notifications/initalized']]
            :_  this
            (send [200 ~ [%application-json *cord]])
          ::
              [~ [%s %'tools/list']]
            :_  this
            (send [200 ~ [%application-json *cord]])
          ::
              [~ [%s %'tools/call']]
            :_  this
            (send [200 ~ [%application-json *cord]])
          ==
        ==
      ==
  --
--
