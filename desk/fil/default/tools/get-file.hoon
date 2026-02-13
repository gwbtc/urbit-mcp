/-  mcp, spider
/+  io=strandio, pf=pretty-file
=,  strand-fail=strand-fail:strand:spider
=>
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
--
::
^-  tool:mcp
:*  'get-file'
  '''
  Fetch a Clay file (local or remote)
  '''
  %-  my
  :~  ['ship' [%string 'The Urbit ID of the ship this file is on. (Default: our ship.)']]
      ['desk' [%string 'The desk this file is in. (Default: %base.)']]
      ['case' [%string 'The $case (revision number or datetime) at which to access this file. (Default: now.)']]
      ['path' [%string 'The remaining filepath.']]
  ==
  ~['path']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  =/  m  (strand:spider ,vase)
  ^-  form:m
  ;<    =bowl:rand
      bind:m
    get-bowl:io
  =/  pax=(unit argument:tool:mcp)  (~(get by args) 'path')
  ?~  pax
    (strand-fail %no-path ~)
  ?>  ?=([%string @t] u.pax)
  =/  path-list=(unit path)  
    (rush p.u.pax ;~(pfix fas (more fas sym)))
  ?~  path-list
    (strand-fail %invalid-path ~)
  =/  her=(unit argument:tool:mcp)   (~(get by args) 'ship')
  =/  dek=(unit argument:tool:mcp)   (~(get by args) 'desk')  
  =/  cast=(unit argument:tool:mcp)  (~(get by args) 'case')
  =/  ship-p=(unit @p)
    ?~  her  ~
    ?>  ?=([%string @t] u.her)
    (rush p.u.her ;~(pfix sig fed:ag))
  =/  desk-tas=(unit @tas)
    ?~  dek  ~
    ?>  ?=([%string @t] u.dek)
    `(@tas p.u.dek)
  =/  cuse=(unit case)
    ?~  cast
      `da+now.bowl
    ?>  ?=([%string @t] u.cast)
    ?+  (@tas -.p:(scan (trip p.u.cast) nuck:so))
      ~
    ::
        %da
      `[%da (@da +.p:(scan (trip p.u.cast) nuck:so))]
    ::
        %ud
      `[%ud (@ud +.p:(scan (trip p.u.cast) nuck:so))]
    ::
        %uv
      `[%uv (@uv +.p:(scan (trip p.u.cast) nuck:so))]
    ==
  ;<  =riot:clay  bind:m
    %:  warp:io
        (fall ship-p our.bowl)
        (fall desk-tas %base)
        ~
        %sing  %x
        (fall cuse da+now.bowl)
        u.path-list
    ==
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      :-  'text'
      :-  %s
      ?~  riot
        'Failed to fetch file.'
      %-  crip
      %-  print-tang-to-wain
      %-  pretty-file:pf
      !<(noun q.r.u.riot)
  ==
==
