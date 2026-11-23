::  %mcp-proxy: tools from remote mcp servers, served by %mcp-server
::
::    holds remote servers, their cached tool lists, and a blocklist
::    of tools, local or remote, that %mcp-server hides. header values
::    stay here: no scry, fact or card to %mcp-server carries them,
::    and we skip dbug, whose /x/dbug/state would.
::
/-  *mcp-proxy, spider
/+  default-agent, mc=mcp-client
|%
+$  card  card:agent:gall
::
++  refresh-interval  ~d1
::
::  +reserved: names a server id must not take; the first segments of
::  %mcp-server's own tool names, and the local blocklist key
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
::  +split: a client-facing name as server id and remote name
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
::  +visible: what /x/tools returns, every unblocked remote tool
++  visible
  |=  [servers=(map server-id remote-mcp-server) blocked=(map server-id (set feature))]
  ^-  (list json)
  %-  zing
  %+  turn  ~(tap by servers)
  |=  [id=server-id srv=remote-mcp-server]
  (skip tools.srv |=(tool=json (blocked-tool blocked id tool)))
::
::  +server-json: one server for a ui; header keys but no values
++  server-json
  |=  [id=server-id srv=remote-mcp-server blocked=(map server-id (set feature))]
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' s+id]
      ['knot' s+(scot %t id)]
      ['url' s+url.srv]
      ['headers' a+(turn headers.srv |=(h=header s+key.h))]
      :-  'tools'
      :-  %a
      %+  turn  tools.srv
      |=  tool=json
      ?.  ?=([%o *] tool)
        tool
      o+(~(put by p.tool) 'blocked' b+(blocked-tool blocked id tool))
  ==
::
++  refresh-card
  |=  [=desk id=server-id srv=remote-mcp-server]
  ^-  card
  :*  %pass  /refresh/(scot %t id)
      %arvo  %k  %lard  desk
      =/  m  (strand:spider ,vase)
      ^-  form:m
      ;<  tools=(list json)  bind:m  (list-tools:mc url.srv headers.srv)
      (pure:m !>(`[@t (list json)]`[url.srv tools]))
  ==
::
++  call-card
  |=  [=desk call=@ta srv=remote-mcp-server name=@t arguments=json]
  ^-  card
  :*  %pass  /call/[call]
      %arvo  %k  %lard  desk
      =/  m  (strand:spider ,vase)
      ^-  form:m
      ;<  res=json  bind:m  (call-tool:mc url.srv headers.srv name arguments)
      (pure:m !>(res))
  ==
::
++  tools-changed
  ^-  card
  [%give %fact ~[/updates] %mcp-proxy-update !>(`update`[%tools-changed ~])]
::
++  tang-text
  |=  =tang
  ^-  @t
  %+  rap  3
  %+  join  '\0a'
  %-  zing
  %+  turn  tang
  |=(=tank (turn (wash [0 80] tank) crip))
--
::
^-  agent:gall
=|  state-0
=*  state  -
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
::  the daily timer lives in behn, not in our state. a reload keeps
::  it, so only +on-init sets one
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
      ::  keep the cached tools until the refresh unless the url moved
      =/  srv=remote-mcp-server
        :+  url.act
          headers.act
        ?~  had  ~
        ?.(=(url.u.had url.act) ~ tools.u.had)
      :-  [(refresh-card q.byk.bowl id.act srv)]~
      state(servers (~(put by servers) id.act srv))
    ::
    ::  keep the server's blocklist, so it comes back if it is added again
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
    ::  a name the cache doesn't hold yet is fine, so a ui can block
    ::  a tool before the first refresh
        %block-tool
      ?<  =('' tool.act)
      `state(blocked (~(put ju blocked) id.act tool.act))
    ::
        %unblock-tool
      `state(blocked (~(del ju blocked) id.act tool.act))
    ::
        %call-tool
      ?>  ((sane %ta) call.act)
      =/  got=(unit [id=server-id name=@t])  (split tool.act)
      ?~  got
        ~|(mcp-proxy-unknown-tool+tool.act !!)
      =/  srv=remote-mcp-server  (~(got by servers) id.u.got)
      ?<  (~(has ju blocked) id.u.got tool.act)
      ?>  (lien tools.srv |=(t=json =(`tool.act (tool-name t))))
      :_  state
      [(call-card q.byk.bowl call.act srv name.u.got arguments.act)]~
    ==
  ::  %mcp-server reads the blocklist too, so a change to it
  ::  changes the tool list as much as a change to /x/tools
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
    [%updates ~]       `this
    [%call call=@ta ~]  `this
  ==
::
++  on-leave  on-leave:def
::
::  no scry here returns header values
++  on-peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+  pole  (on-peek:def `path`pole)
  ::
  ::  .^(json %gx /=mcp-proxy=/tools/json)
  ::  unblocked remote tools as one array, for %mcp-server
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
  ::  refresh on a wake even if behn reports an error, so one bad
  ::  wake doesn't end the chain
      [%timer ~]
    ?>  ?=([%behn %wake *] sign-arvo)
    :_  this
    :-  [%pass /timer %arvo %b %wait (add now.bowl refresh-interval)]
    %+  turn  ~(tap by servers)
    |=  [id=server-id srv=remote-mcp-server]
    (refresh-card q.byk.bowl id srv)
  ::
  ::  on failure keep the old tools; a remote that is down for a day
  ::  keeps its last good list
      [%refresh k=@ta ~]
    ?>  ?=([%khan %arow *] sign-arvo)
    =/  id=server-id  (slav %t k.pole)
    ?:  ?=(%| -.p.sign-arvo)
      %-  (slog leaf+"mcp-proxy: refresh of {(trip id)} failed" tang.p.p.sign-arvo)
      `this
    =+  !<([url=@t tools=(list json)] q.p.p.sign-arvo)
    =/  srv=(unit remote-mcp-server)  (~(get by servers) id)
    ::  the server went away, or moved, while we listed it
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
      [%call call=@ta ~]
    ?>  ?=([%khan %arow *] sign-arvo)
    =/  res=json
      ?:  ?=(%& -.p.sign-arvo)
        !<(json q.p.p.sign-arvo)
      %+  frond:enjs:format  'error'
      %-  pairs:enjs:format
      :~  ['code' n+~.-32603]
          :-  'message'
          :-  %s
          %+  rap  3
          :~  'Remote tool call failed: %'
              mote.p.p.sign-arvo
              '\0a'
              (tang-text tang.p.p.sign-arvo)
          ==
      ==
    :_  this
    :~  [%give %fact ~[/call/[call.pole]] %mcp-proxy-update !>(`update`[%tool-result res])]
        [%give %kick ~[/call/[call.pole]] ~]
    ==
  ==
::
++  on-fail   on-fail:def
--
