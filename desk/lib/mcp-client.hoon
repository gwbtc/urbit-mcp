::  mcp-client: strands that speak MCP over HTTP to a remote server
::
::    each call opens a fresh connection, so no session outlives a
::    thread. each protocol version keeps its rules in its own core;
::    the arms above them don't know which version they speak.
::
/-  mp=mcp-proxy
/+  io=strandio, libstrand=strand, jut=json-utils
=,  strand=strand:libstrand
|%
::
::  .version: what a 2025-era server agreed to in initialize
+$  conn
  $%  [%~.2026-07-28 url=@t headers=(list header:mp)]
      $:  %~.2025-11-25
          url=@t
          headers=(list header:mp)
          version=@t
          session=(unit @t)
      ==
  ==
::
::  .body: the json-rpc message, if any, that answers our request
+$  reply
  $:  status=@ud
      headers=header-list:http
      body=(unit json)
  ==
::
::  wait this long for a reply to a handshake or tools/list
++  list-timeout  ~s30
::  wait this long for a reply to tools/call
++  call-timeout  ~m5
::  stop paging tools/list after this many pages
++  max-pages     50
::
++  client-info
  ^-  json
  %-  pairs:enjs:format
  :~  ['name' s+'urbit-mcp-proxy']
      ['version' s+'1.0.0']
  ==
::
::  +list-tools: every tool the remote lists, across pages
++  list-tools
  |=  [url=@t headers=(list header:mp)]
  =/  m  (strand ,(list json))
  ^-  form:m
  ;<  =conn  bind:m  (open url headers)
  =|  pages=(list (list json))
  =|  cursor=(unit json)
  =/  page=@ud  1
  |-  ^-  form:m
  =*  loop  $
  ?:  (gth page max-pages)
    (pure:m (zing (flop pages)))
  ;<  rep=reply  bind:m
    %:  send-rpc
        conn
        `page
        'tools/list'
        ?~(cursor ~ ['cursor' u.cursor]~)
        list-timeout
    ==
  ;<  res=json  bind:m  (result url rep)
  =/  tools=(unit json)  (~(get jo:jut res) /tools)
  =.  pages  [?.(?=([~ %a *] tools) ~ p.u.tools) pages]
  =/  next=(unit json)  (~(get jo:jut res) /'nextCursor')
  ?.  ?=([~ %s *] next)
    (pure:m (zing (flop pages)))
  loop(page +(page), cursor next, pages pages)
::
::  +call-tool: call .name with .arguments; a json-rpc error from
::  the remote is a result, not a failure
++  call-tool
  |=  [url=@t headers=(list header:mp) name=@t arguments=json]
  =/  m  (strand ,result:mp)
  ^-  form:m
  ;<  =conn  bind:m  (open url headers)
  ;<  rep=reply  bind:m
    %:  send-rpc
        conn
        `1
        'tools/call'
        ~[['name' s+name] ['arguments' arguments]]
        call-timeout
    ==
  ?~  body.rep
    (fail %mcp-error leaf+"{(trip url)}: http {<status.rep>} with no reply" ~)
  =/  err=(unit json)  (~(get jo:jut u.body.rep) /error)
  ?^  err
    =/  code=(unit json)  (~(get jo:jut u.err) /code)
    =/  msg=(unit json)   (~(get jo:jut u.err) /message)
    %-  pure:m
    :*  %error
        ?.(?=([~ %n *] code) ~.-32603 p.u.code)
        ?.(?=([~ %s *] msg) 'Remote MCP server error' p.u.msg)
        (~(get jo:jut u.err) /data)
    ==
  ?^  msg=(reply-error rep)
    (fail %mcp-error leaf+"{(trip url)}: {(trip u.msg)}" ~)
  (pure:m [%result (~(got jo:jut u.body.rep) /result)])
::
::  +open: agree on a protocol with the remote
++  open
  |=  [url=@t headers=(list header:mp)]
  =/  m  (strand ,conn)
  ^-  form:m
  ;<  new=(unit conn)  bind:m  (open:mcp-2026-07-28 url headers)
  ?^  new
    (pure:m u.new)
  (open:mcp-2025-11-25 url headers)
::
::  +not-self: fail with %own-endpoint if .name is the name of our
::  own %mcp-server, so we don't serve our own tools back to ourselves
++  not-self
  |=  [url=@t name=(unit json)]
  =/  m  (strand ,~)
  ^-  form:m
  ;<  our=@p  bind:m  get-our:io
  ?.  =(name `s+(server-name:mp our))
    (pure:m ~)
  (fail %own-endpoint leaf+"{(trip url)} is this ship's own %mcp-server" ~)
::
::  +send-rpc: send one json-rpc message over .conn; with no .id,
::  a notification
++  send-rpc
  |=  $:  =conn
          id=(unit @ud)
          method=@t
          params=(list [@t json])
          timeout=@dr
      ==
  =/  m  (strand ,reply)
  ^-  form:m
  =/  [url=@t hed=(list header:mp) ps=(list [@t json])]
    ?-    -.conn
        %~.2026-07-28
      =/  name=(unit json)  (~(get by (malt params)) 'name')
      :+  url.conn
        %+  weld  headers.conn
        %+  headers:mcp-2026-07-28
          method
        ?.  =('tools/call' method)  ~
        ?.  ?=([~ %s *] name)  ~
        `p.u.name
      [['_meta' meta:mcp-2026-07-28] params]
    ::
        %~.2025-11-25
      :+  url.conn
        ::  initialize comes before any version or session
        ?:  =('initialize' method)
          headers.conn
        %+  weld  headers.conn
        (headers:mcp-2025-11-25 version.conn session.conn)
      params
    ==
  %:  post
      url
      hed
      %-  pairs:enjs:format
      ^-  (list [@t json])
      :+  ['jsonrpc' s+'2.0']
        ['method' s+method]
      :-  ['params' (pairs:enjs:format ps)]
      ?~(id ~ ['id' (numb:enjs:format u.id)]~)
      (bind id numb:enjs:format)
      timeout
  ==
::
::  +post: send .body and wait up to .timeout for the reply. .id picks
::  the reply out of an sse stream; a notification has no .id and
::  wants no body. iris has no timeout of its own, so we race it
::  against a behn timer.
++  post
  |=  $:  url=@t
          headers=(list header:mp)
          body=json
          id=(unit json)
          timeout=@dr
      ==
  =/  m  (strand ,reply)
  ^-  form:m
  ;<  now=@da  bind:m  get-time:io
  =/  until=@da  (add now timeout)
  =/  =request:http
    :^  %'POST'  url
      ^-  header-list:http
      :*  ['content-type' 'application/json']
          ['accept' 'application/json, text/event-stream']
          headers
      ==
    `(as-octs:mimes:html (en:json:html body))
  ;<  ~  bind:m
    %-  send-raw-cards:io
    :~  [%pass /request %arvo %i %request request *outbound-config:iris]
        [%pass /timeout/(scot %da until) %arvo %b %wait until]
    ==
  ;<  res=(unit raw-reply)  bind:m  (take-reply until)
  ?~  res
    ;<  ~  bind:m  (send-raw-card:io [%pass /request %arvo %i %cancel-request ~])
    (fail %mcp-timeout leaf+"{(trip url)}: no reply in {<timeout>}" ~)
  =/  [hed=response-header:http file=(unit mime-data:iris)]  u.res
  %-  pure:m
  :+  status-code.hed
    headers.hed
  ?~  file
    ~
  ?~  id
    ~
  ?.  =("text/event-stream" (scag 17 (cass (trip type.u.file))))
    (de:json:html q.data.u.file)
  (sse-reply q.data.u.file u.id)
::
+$  raw-reply  [response-header:http (unit mime-data:iris)]
::
::  +take-reply: the iris response, or ~ once behn wakes us at .until
++  take-reply
  |=  until=@da
  =/  m  (strand ,(unit raw-reply))
  ^-  form:m
  |=  tin=strand-input:strand
  ?+  in.tin  `[%skip ~]
      ~  `[%wait ~]
  ::
      [~ %sign [%request ~] %iris %http-response %cancel *]
    `[%fail %http-request-cancelled ~]
  ::
      [~ %sign [%request ~] %iris %http-response %finished *]
    =/  rep  client-response.sign-arvo.u.in.tin
    ?>  ?=(%finished -.rep)
    :_  [%done `[response-header.rep full-file.rep]]
    [%pass /timeout/(scot %da until) %arvo %b %rest until]~
  ::
      [~ %sign [%timeout @ ~] %behn %wake *]
    ?.  =((scot %da until) i.t.wire.u.in.tin)
      `[%skip ~]
    `[%done ~]
  ==
::
::  +fail: a strand of any type that fails at once
++  fail
  |=  [=term =tang]
  |=  strand-input:strand
  [~ %fail term tang]
::
::  +result: the result of a successful json-rpc reply, or fail
++  result
  |=  [url=@t rep=reply]
  =/  m  (strand ,json)
  ^-  form:m
  ?^  msg=(reply-error rep)
    (fail %mcp-error leaf+"{(trip url)}: {(trip u.msg)}" ~)
  (pure:m (~(got jo:jut (need body.rep)) /result))
::
::  +reply-error: why .rep is not a successful json-rpc reply
++  reply-error
  |=  rep=reply
  ^-  (unit @t)
  ?:  |((lth status.rep 200) (gte status.rep 300))
    `(crip "http {<status.rep>}")
  ?~  body.rep
    `'no json-rpc reply'
  =/  err=(unit json)  (~(get jo:jut u.body.rep) /error)
  ?^  err
    `(crip "json-rpc error {(trip (en:json:html u.err))}")
  ?.  ?=([~ %o *] (~(get jo:jut u.body.rep) /result))
    `'reply has no result object'
  ~
::
::  +sse-reply: the json-rpc response to .id in an sse body
++  sse-reply
  |=  [body=@t id=json]
  ^-  (unit json)
  =/  msgs=(list json)  (murn (sse-events body) de:json:html)
  |-
  ?~  msgs
    ~
  ?:  ?&  =(`id (~(get jo:jut i.msgs) /id))
          ?|  (~(has jo:jut i.msgs) /result)
              (~(has jo:jut i.msgs) /error)
      ==  ==
    `i.msgs
  $(msgs t.msgs)
::
::  +sse-events: the data of each event in an sse body; an event's
::  data lines join with newlines, and a blank line ends the event
++  sse-events
  |=  body=@t
  ^-  (list @t)
  =/  lines=wain  (to-wain:format body)
  =|  out=(list @t)
  =|  cur=(list @t)
  |-
  ?~  lines
    (flop ?~(cur out [(rap 3 (join '\0a' (flop cur))) out]))
  =/  line=@t
    =/  len  (met 3 i.lines)
    ?:  &(!=(0 len) =('\0d' (cut 3 [(dec len) 1] i.lines)))
      (end [3 (dec len)] i.lines)
    i.lines
  ?:  =('' line)
    %=  $
      lines  t.lines
      cur    ~
      out    ?~(cur out [(rap 3 (join '\0a' (flop cur))) out])
    ==
  ?.  =('data:' (end [3 5] line))
    $(lines t.lines)
  =/  data=@t  (rsh [3 5] line)
  =?  data  =(' ' (end 3 data))  (rsh [3 1] data)
  $(lines t.lines, cur [data cur])
::
::  +get-header: case-insensitive header lookup
++  get-header
  |=  [key=@t hed=header-list:http]
  ^-  (unit @t)
  =/  want=tape  (cass (trip key))
  |-
  ?~  hed
    ~
  ?:  =(want (cass (trip key.i.hed)))
    `value.i.hed
  $(hed t.hed)
::
::  stateless requests: discover first, then send the version header
::  and _meta that our own +handle-req in %mcp-server expects
++  mcp-2026-07-28
  |%
  ++  version  ~.2026-07-28
  ::
  ::  +open: ~ unless the remote lists 2026-07-28 in server/discover
  ++  open
    |=  [url=@t headers=(list header:mp)]
    =/  m  (strand ,(unit conn))
    ^-  form:m
    =/  =conn  [%~.2026-07-28 url headers]
    ;<  rep=reply  bind:m  (send-rpc conn `0 'server/discover' ~ list-timeout)
    ?^  (reply-error rep)
      (pure:m ~)
    =/  res=json  (~(got jo:jut (need body.rep)) /result)
    =/  meta=(unit json)  (~(get jo:jut res) /'_meta')
    =/  info=(unit json)
      ?.  ?=([~ %o *] meta)  ~
      (~(get by p.u.meta) 'io.modelcontextprotocol/serverInfo')
    ;<  ~  bind:m  (not-self url ?~(info ~ (~(get jo:jut u.info) /name)))
    =/  vs=(unit json)  (~(get jo:jut res) /'supportedVersions')
    %-  pure:m
    ?.  ?=([~ %a *] vs)
      ~
    ?.  (lien p.u.vs |=(v=json =(v s+version)))
      ~
    `conn
  ::
  ++  meta
    ^-  json
    %-  pairs:enjs:format
    :~  ['io.modelcontextprotocol/protocolVersion' s+version]
        ['io.modelcontextprotocol/clientCapabilities' o+~]
        ['io.modelcontextprotocol/clientInfo' client-info]
    ==
  ::
  ::  +headers: tools/call also names its tool, in base64
  ::  when the name is not printable ascii
  ++  headers
    |=  [method=@t name=(unit @t)]
    ^-  (list header:mp)
    :*  ['MCP-Protocol-Version' version]
        ['Mcp-Method' method]
        ?~  name
          ~
        :_  ~
        :-  'Mcp-Name'
        ?:  (levy (trip u.name) |=(c=@ &((gte c 0x20) (lte c 0x7e))))
          u.name
        %+  rap  3
        :~  '=?base64?'
            (en:base64:mimes:html (as-octs:mimes:html u.name))
            '?='
        ==
    ==
  --
::
::  the initialize handshake and a session id
++  mcp-2025-11-25
  |%
  ++  version  ~.2025-11-25
  ::
  ::  +open: initialize, keep Mcp-Session-Id, then send
  ::  notifications/initialized
  ++  open
    |=  [url=@t headers=(list header:mp)]
    =/  m  (strand ,conn)
    ^-  form:m
    =/  init=conn  [%~.2025-11-25 url headers version ~]
    ;<  rep=reply  bind:m
      %:  send-rpc
          init
          `0
          'initialize'
          :~  ['protocolVersion' s+version]
              ['capabilities' o+~]
              ['clientInfo' client-info]
          ==
          list-timeout
      ==
    ;<  res=json  bind:m  (result url rep)
    ;<  ~  bind:m  (not-self url (~(get jo:jut res) /'serverInfo'/name))
    =/  agreed=(unit json)  (~(get jo:jut res) /'protocolVersion')
    =/  =conn
      :*  %~.2025-11-25
          url
          headers
          ?.(?=([~ %s *] agreed) version p.u.agreed)
          (get-header 'mcp-session-id' headers.rep)
      ==
    ;<  ack=reply  bind:m
      (send-rpc conn ~ 'notifications/initialized' ~ list-timeout)
    ?:  |((lth status.ack 200) (gte status.ack 300))
      (fail %mcp-error leaf+"{(trip url)}: http {<status.ack>} to notifications/initialized" ~)
    (pure:m conn)
  ::
  ++  headers
    |=  [ver=@t session=(unit @t)]
    ^-  (list header:mp)
    :-  ['MCP-Protocol-Version' ver]
    ?~(session ~ ['Mcp-Session-Id' u.session]~)
  --
--
