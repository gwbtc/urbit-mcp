::  mcp-fileserver: serves the web UI from clay
::
::    copy of foo-fileserver pattern.
::    reads configuration from /app/fileserver/config.hoon.
::
/=  config  /app/fileserver/config
::
|%
++  web-root     ^-  (list @t)                  web-root:config
::
++  defaults
  |%
  ++  file-root  ^-  path                       /web
  ++  tombstone  ^-  ?                          |
  ++  index      ^-  $@(~ [~ path])             `/index/html
  ++  extension  ^-  ?(%need %path %fall)       %need
  ++  auth       ^-  $@(? [? (list [path ?])])  &
  --
::
++  file-root  ^-  path
  !@(file-root:config file-root:defaults file-root:config)
::
++  tombstone  ^-  ?
  !@(tombstone:config tombstone:defaults tombstone:config)
::
++  index  ^-  $@(?(~ %apache) [~ u=path])
  !@(index:config index:defaults index:config)
::
++  extension  ^-  ?(%need %path %fall)
  !@(extension:config extension:defaults extension:config)
::
++  auth  ^~  ^-  (map path ?)
  =/  val=$@(? [? (list [path ?])])
    !@(auth:config auth:defaults auth:config)
  ?@  val  (~(put by *(map path ?)) / val)
  (~(gas by *(map path ?)) [/ -.val] +.val)
--
::
|%
+$  state-0
  $:  %0
      foot=path
      woot=path
      cash=(set @t)
  ==
::
+$  card  card:agent:gall
::
+$  cart  $@(~ $^((lest card) $%([~ card] card)))
++  zang
  |=  a=(list cart)
  ^-  (list card)
  %-  zing
  %+  turn  a
  |=  b=cart
  ^-  (list card)
  ?~  b  ~
  ?^  -.b  b
  ?~  -.b  [+.b]~
  [b]~
::
++  store
  |=  [url=@t entry=(unit cache-entry:eyre)]
  ^-  card
  [%pass /eyre/cache %arvo %e %set-response url entry]
::
++  read-next
  |=  [[our=@p =desk now=@da] =path]
  ^-  card
  =;  =task:clay
    [%pass [%clay %next path] %arvo %c task]
  [%warp our desk ~ %next %z da+now path]
::
++  set-norm
  |=  [[our=@p =desk] =path keep=?]
  ^-  card
  =;  =task:clay
    [%pass [%clay %norm path] %arvo %c task]
  [%tomb %norm our desk (~(put of *norm:clay) path keep)]
::
++  run-tombstone
  ^-  card
  [%pass /clay/tomb %arvo %c %tomb %pick ~]
--
::
=|  state-0
=*  state  -
::
^-  agent:gall
|_  =bowl:gall
+*  this  .
::
++  on-init
  ^-  (quip card _this)
  =.  foot  file-root
  =.  woot  web-root
  :_  this
  :+  [%pass /eyre/connect %arvo %e %connect [~ web-root] dap.bowl]
    (read-next [our q.byk now]:bowl file-root)
  ?.  tombstone  ~
  :~  (set-norm [our q.byk]:bowl file-root |)
      run-tombstone
  ==
::
++  on-save
  !>(state)
::
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  =/  old  !<(state-0 ole)
  :_  this(foot file-root, woot web-root, cash ~)
  %-  zang
  :~  ?:  =(foot.old file-root)  ~
      (read-next [our q.byk now]:bowl file-root)
    ::
      ?.  tombstone
        (set-norm [our q.byk]:bowl foot.old &)
      :~  (set-norm [our q.byk]:bowl file-root |)
          run-tombstone
      ==
    ::
      (turn ~(tap in cash.old) (curr store ~))
    ::
      ?:  =(woot.old web-root)  ~
      :~  [%pass /eyre/connect %arvo %e %connect [~ woot.old] dap.bowl]
          [%pass /eyre/connect %arvo %e %disconnect [~ woot.old]]
          [%pass /eyre/connect %arvo %e %connect [~ web-root] dap.bowl]
      ==
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?:  ?=(%dbug mark)
    ~&  state=state
    [~ this]
  ~|  mark=mark
  ?>  ?=(%handle-http-request mark)
  =+  !<([rid=@ta inbound-request:eyre] vase)
  ::
  =;  [sav=$@(%| [%& auth=?]) pay=simple-payload:http]
    =/  serve=(list card)
      =?  pay  &(?=([%& %&] sav) !authenticated)
        [[403 ~] `(as-octs:mimes:html 'unauthorized')]
      =?  data.pay  ?=(%'HEAD' method.request)
        ~
      =/  =path  /http-response/[rid]
      :~  [%give %fact ~[path] [%http-response-header !>(response-header.pay)]]
          [%give %fact ~[path] [%http-response-data !>(data.pay)]]
          [%give %kick ~[path] ~]
      ==
    [serve this]
  ?.  ?=(?(%'GET' %'HEAD') method.request)
    [%| [405 ~] `(as-octs:mimes:html 'read-only resource')]
  =+  ^-  [[ext=(unit @ta) site=(list @t)] args=(list [key=@t value=@t])]
    =-  (fall - [[~ ~] ~])
    (rush url.request ;~(plug apat:de-purl:html yque:de-purl:html))
  ?.  =(web-root (scag (lent web-root) site))
    [%| [500 ~] `(as-octs:mimes:html 'bad route')]
  ::  redirect /apps/mcp to /apps/mcp/
  ?:  &(=(web-root site) ?=(~ ext))
    [%| [301 ['location' (cat 3 (spat web-root) '/')]~] ~]
  =.  site  (slag (lent web-root) site)
  :-  :-  %&
      |-
      ?:  =(/ site)  (~(got by auth) /)
      %-  (bond |.(^$(site (snip site))))
      (~(get by auth) site)
  =/  target=$@(?(~ %apache) [pax=path ext=@ta])
    |-
    ?:  &(?=(~ ext) ?=([%$ *] (flop site)))
      =+  index=index
      ?@  index  index
      [(weld (snip site) u.index) (rear u.index)]
    ?^  ext  [(snoc site u.ext) u.ext]
    ?-  =<(. extension)
      %need  ~
      %path  [site (rear site)]
      %fall  $(site (snoc site %$))
    ==
  ?~  target
    [[404 ~] `(as-octs:mimes:html 'not found')]
  =/  bas=path
    /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)
  ?^  target
    =/  =path
      :(weld bas file-root pax.target)
    ?.  .^(? %cu path)
      ~&  [dap.bowl %not-found path=path]
      [[404 ~] `(as-octs:mimes:html 'not found')]
    =+  .^(file=^vase %cr path)
    =+  ~|  [%no-mime-conversion from=ext.target]
        .^(=tube:clay %cc (weld bas /[ext.target]/mime))
    =+  !<(=mime (tube file))
    :_  `q.mime
    [200 ['content-type' (rsh 3^1 (spat p.mime))] ['cache-control' 'no-cache'] ~]
  ?>  ?=(%apache target)
  [[200 ['content-type' 'text/html;charset=UTF-8']~] `(as-octs:mimes:html 'directory listing not supported')]
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  ?=([%http-response @ ~] path)
  [~ this]
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ~|  wire=wire
  ?+  wire  !!
      [%eyre %connect ~]
    ~|  sign=+<.sign
    ?>  ?=(%bound +<.sign)
    ~?  !accepted.sign  [dap.bowl %binding-rejected binding.sign]
    [~ this]
  ::
      [%eyre %cache ~]
    ~|  sign=+<.sign
    ~|  %did-not-expect-gift
    !!
  ::
      [%clay %next *]
    ?.  =(t.t.wire file-root)  [~ this]
    ~|  sign=+<.sign
    ?>  ?=(%writ +<.sign)
    :_  this(cash ~)
    %-  zang
    :+  ?:(tombstone ~ run-tombstone)
      (read-next [our q.byk now]:bowl file-root)
    (turn ~(tap in cash) (curr store ~))
  ==
::
++  on-leave  |=(* [~ this])
++  on-agent  |=(* [~ this])
++  on-peek   |=(* ~)
::
++  on-fail
  |=  [=term =tang]
  ^-  (quip card _this)
  %-  (slog (rap 3 dap.bowl ' +on-fail: ' term ~) tang)
  [~ this]
--
