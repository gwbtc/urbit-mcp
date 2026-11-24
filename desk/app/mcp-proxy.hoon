::  %mcp-proxy: tools from remote mcp servers, served by %mcp-server
::
::    header values never leave this agent. we skip dbug, whose
::    /x/dbug/state would leak them.
::
/-  *mcp-proxy, spider
/+  default-agent, mc=mcp-client
::
^-  agent:gall
=|  state-0
=*  state  -
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
::  behn keeps the daily timer across reloads, so only +on-init sets it
++  on-init
  ^-  (quip card _this)
  :_  this
  [%pass /timer %arvo %b %wait (add now.bowl refresh-interval)]~
::
++  on-save  !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  `this(state !<(state-0 old))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?>  =(src our):bowl
  ?.  ?=(%mcp-proxy-action mark)
    (on-poke:def mark vase)
  =/  act  !<(action vase)
  =/  old=_state  state
  =^  cards  state
    ^-  (quip card _state)
    ?-    -.act
        %add-mcp-server
      ?>  (valid-id our.bowl id.act)
      =/  had=(unit remote-mcp-server)  (~(get by servers) id.act)
      ::  keep cached tools unless the url changed
      =/  srv=remote-mcp-server
        :+  url.act
          headers.act
        ?~  had  ~
        ?.(=(url.u.had url.act) ~ tools.u.had)
      :-  [(refresh-card q.byk.bowl id.act srv)]~
      state(servers (~(put by servers) id.act srv))
    ::
    ::  the blocklist entry stays for when the server comes back
        %delete-mcp-server
      `state(servers (~(del by servers) id.act))
    ::
        %refresh-mcp-server
      :_  state
      ?~  id.act
        %+  turn  ~(tap by servers)
        |=  [id=server-id srv=remote-mcp-server]
        (refresh-card q.byk.bowl id srv)
      [(refresh-card q.byk.bowl u.id.act (~(got by servers) u.id.act))]~
    ::
    ::  the tool need not be cached yet
        %block-tool
      ?<  =('' tool.act)
      `state(blocked (~(put ju blocked) id.act tool.act))
    ::
        %unblock-tool
      `state(blocked (~(del ju blocked) id.act tool.act))
    ::
        %call-tool
      ?>  ((sane %ta) uuid.act)
      =/  got=(unit [id=server-id name=@t])  (split tool.act)
      ?~  got
        ~|(mcp-proxy-unknown-tool+tool.act !!)
      =/  srv=remote-mcp-server  (~(got by servers) id.u.got)
      ?<  (~(has ju blocked) id.u.got tool.act)
      ?>  (lien tools.srv |=(t=json =(`tool.act (tool-name t))))
      :_  state
      [(call-card q.byk.bowl uuid.act srv name.u.got arguments.act)]~
    ==
  ::  %mcp-server also reads the blocklist for its own tools
  :_  this
  ?:  ?&  =(blocked.old blocked)
          =((visible servers.old blocked.old) (visible servers blocked))
      ==
    cards
  (snoc cards tools-changed)
::
++  on-watch
  |=  =(pole knot)
  ^-  (quip card _this)
  ?>  =(src our):bowl
  ?+  pole  (on-watch:def `path`pole)
    [%updates ~]        `this
    [%call uuid=@ta ~]  `this
  ==
::
++  on-leave  on-leave:def
::
::  blocked tools appear only in /x/blocked
++  on-peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+  pole  (on-peek:def `path`pole)
  ::
  ::  .^(json %gx /=mcp-proxy=/tools/json)
      [%x %tools ~]
    ``json+!>(`json`a+(visible servers blocked))
  ::
  ::  .^((map server-id (set feature)) %gx /=mcp-proxy=/blocked/mcp-proxy-blocked)
  ::  .^(json %gx /=mcp-proxy=/blocked/json)
      [%x %blocked ~]
    ``mcp-proxy-blocked+!>(blocked)
  ::
  ::  .^(json %gx /=mcp-proxy=/servers/json)
      [%x %servers ~]
    :^  ~  ~  %json
    !>  ^-  json
    :-  %a
    %+  turn  ~(tap by servers)
    |=  [id=server-id srv=remote-mcp-server]
    (server-json id srv blocked)
  ::
  ::  .^(json %gx /=mcp-proxy=/server/(scot %t id)/json)
      [%x %server k=@ta ~]
    =/  id=(unit server-id)  (slaw %t k.pole)
    ?~  id
      [~ ~]
    =/  srv=(unit remote-mcp-server)  (~(get by servers) u.id)
    ?~  srv
      [~ ~]
    ``json+!>((server-json u.id u.srv blocked))
  ==
::
++  on-agent  on-agent:def
::
++  on-arvo
  |=  [=(pole knot) =sign-arvo]
  ^-  (quip card _this)
  ?+    pole  (on-arvo:def `wire`pole sign-arvo)
  ::
  ::  refresh even on a behn error, so the chain goes on
      [%timer ~]
    ?>  ?=([%behn %wake *] sign-arvo)
    :_  this
    :-  [%pass /timer %arvo %b %wait (add now.bowl refresh-interval)]
    %+  turn  ~(tap by servers)
    |=  [id=server-id srv=remote-mcp-server]
    (refresh-card q.byk.bowl id srv)
  ::
  ::  a failed refresh keeps the last good list, unless the remote
  ::  turned out to be our own %mcp-server
      [%refresh k=@ta h=@ta ~]
    ?>  ?=([%khan %arow *] sign-arvo)
    =/  id=server-id  (slav %t k.pole)
    ?:  ?=(%| -.p.sign-arvo)
      =/  =tang  tang.p.p.sign-arvo
      =/  srv=(unit remote-mcp-server)  (~(get by servers) id)
      ?.  ?&  ?=(^ tang)
              =("own-endpoint" ~(ram re i.tang))
              ?=(^ srv)
              =(h.pole (url-hash url.u.srv))
          ==
        %-  (slog leaf+"mcp-proxy: refresh of {(trip id)} failed" tang)
        `this
      %-  (slog leaf+"mcp-proxy: dropped {(trip id)}, this ship's own %mcp-server" ~)
      =/  before=(list json)  (visible servers blocked)
      =.  servers  (~(del by servers) id)
      :_  this
      ?:  =(before (visible servers blocked))
        ~
      ~[tools-changed]
    =+  !<([url=@t tools=(list json)] q.p.p.sign-arvo)
    =/  srv=(unit remote-mcp-server)  (~(get by servers) id)
    ::  drop a list for a server deleted or moved since
    ?~  srv
      `this
    ?.  =(url url.u.srv)
      `this
    =/  before=(list json)  (visible servers blocked)
    =.  servers  (~(put by servers) id u.srv(tools (murn tools (cury rename id))))
    :_  this
    ?:  =(before (visible servers blocked))
      ~
    ~[tools-changed]
  ::
      [%call uuid=@ta ~]
    ?>  ?=([%khan %arow *] sign-arvo)
    =/  res=result
      ?:  ?=(%& -.p.sign-arvo)
        !<(result q.p.p.sign-arvo)
      :*  %error
          ~.-32603
          (rap 3 'Remote tool call failed: ' (tang-text tang.p.p.sign-arvo) ~)
          ~
      ==
    :_  this
    :~  [%give %fact ~[/call/[uuid.pole]] %mcp-proxy-update !>(`update`[%tool-result res])]
        [%give %kick ~[/call/[uuid.pole]] ~]
    ==
  ==
::
++  on-fail   on-fail:def
--
::
|%
+$  card  card:agent:gall
::
++  refresh-interval  ~d1
::
::  +reserved: prefixes of %mcp-server's own tools, and the local key
++  reserved
  |=  our=@p
  ^-  (set server-id)
  (silt ~['mcp' 'dojo' 'aqua' (local-key our)])
::
++  valid-id
  |=  [our=@p id=server-id]
  ^-  ?
  ?&  !=('' id)
      ?=(~ (find "/" (trip id)))
      !(~(has in (reserved our)) id)
  ==
::
::  +split: <server-id>/<name> as server id and remote name
++  split
  |=  =feature
  ^-  (unit [id=server-id name=@t])
  =/  i=(unit @ud)  (find "/" (trip feature))
  ?~  i
    ~
  `[(end [3 u.i] feature) (rsh [3 +(u.i)] feature)]
::
++  tool-name
  |=  tool=json
  ^-  (unit @t)
  ?.  ?=([%o *] tool)
    ~
  =/  name=(unit json)  (~(get by p.tool) 'name')
  ?.  ?=([~ %s *] name)
    ~
  `p.u.name
::
::  +rename: prefix a remote tool's name with its server id
++  rename
  |=  [id=server-id tool=json]
  ^-  (unit json)
  =/  name=(unit @t)  (tool-name tool)
  ?~  name
    ~
  ?>  ?=([%o *] tool)
  `o+(~(put by p.tool) 'name' s+(rap 3 id '/' u.name ~))
::
++  blocked-tool
  |=  [blocked=(map server-id (set feature)) id=server-id tool=json]
  ^-  ?
  =/  name=(unit @t)  (tool-name tool)
  ?~  name
    &
  (~(has ju blocked) id u.name)
::
++  unblocked
  |=  [blocked=(map server-id (set feature)) id=server-id tools=(list json)]
  ^-  (list json)
  (skip tools |=(tool=json (blocked-tool blocked id tool)))
::
::  +visible: every unblocked remote tool
++  visible
  |=  [servers=(map server-id remote-mcp-server) blocked=(map server-id (set feature))]
  ^-  (list json)
  %-  zing
  %+  turn  ~(tap by servers)
  |=  [id=server-id srv=remote-mcp-server]
  (unblocked blocked id tools.srv)
::
::  +server-json: header keys but no values
++  server-json
  |=  [id=server-id srv=remote-mcp-server blocked=(map server-id (set feature))]
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' s+id]
      ['knot' s+(scot %t id)]
      ['url' s+url.srv]
      ['headers' a+(turn headers.srv |=(h=header s+key.h))]
      ['tools' a+(unblocked blocked id tools.srv)]
  ==
::
++  refresh-card
  |=  [=desk id=server-id srv=remote-mcp-server]
  ^-  card
  :*  %pass  /refresh/(scot %t id)/(url-hash url.srv)
      %arvo  %k  %lard  desk
      =/  m  (strand:spider ,vase)
      ^-  form:m
      ;<  tools=(list json)  bind:m  (list-tools:mc url.srv headers.srv)
      (pure:m !>(`[@t (list json)]`[url.srv tools]))
  ==
::
++  call-card
  |=  [=desk uuid=@ta srv=remote-mcp-server name=@t arguments=json]
  ^-  card
  :*  %pass  /call/[uuid]
      %arvo  %k  %lard  desk
      =/  m  (strand:spider ,vase)
      ^-  form:m
      ;<  res=result  bind:m  (call-tool:mc url.srv headers.srv name arguments)
      (pure:m !>(res))
  ==
::
::  +url-hash: ties a refresh to the url it listed
++  url-hash
  |=  url=@t
  ^-  @ta
  (scot %uv (sham url))
::
++  tools-changed
  ^-  card
  [%give %fact ~[/updates] %mcp-proxy-update !>(`update`[%tools-changed ~])]
::
++  tang-text
  |=  =tang
  ^-  @t
  %-  of-wain:format
  %-  zing
  %+  turn  tang
  |=  =tank
  ^-  wain
  %+  turn  (wash [0 80] tank)
  |=(=tape (crip tape))
--
