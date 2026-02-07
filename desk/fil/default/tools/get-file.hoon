/-  mcp, spider
/+  io=strandio, jut=json-utils, pf=pretty-file
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
  Fetch the text of a file from Clay, whether local or remote.
  Must not be a directory.
  '''
  %-  my
  :~  ['ship' [%string 'The Urbit ID of the ship this file is on. (Default: our ship.)']]
      ['desk' [%string 'The desk this file is in. (Default: %base.)']]
      ['case' [%string 'The $case (revision number or datetime) at which to access this file. (Default: now.)']]
      ['path' [%string 'The remaining filepath.']]
  ==
  ~['path']
  ^-  thread-builder:mcp
  |=  args=(map @t json)
  =/  m  (strand:spider ,vase)
  ^-  form:m
  ;<    =bowl:rand
      bind:m
    get-bowl:io
  =/  jon=json  [%o args]
  =/  pax=(unit path)  (~(deg jo:jut jon) /path pa:dejs:format)
  ?~  pax
    (strand-fail %no-path ~)
  =/  her=(unit ship)   (~(deg jo:jut jon) /ship (se %p):dejs:format)
  =/  dek=(unit desk)   (~(deg jo:jut jon) /desk (se %tas):dejs:format)
  =/  cast=(unit tape)  (~(deg jo:jut jon) /case sa:dejs:format)
  =/  cuse=(unit case)
    ?~  cast
      `da+now.bowl
    ?+  (@tas -.p:(scan u.cast nuck:so))
      ~
    ::
        %da
      `[%da (@da +.p:(scan u.cast nuck:so))]
    ::
        %ud
      `[%ud (@ud +.p:(scan u.cast nuck:so))]
    ::
        %uv
      `[%uv (@uv +.p:(scan u.cast nuck:so))]
    ==
  ;<  =riot:clay  bind:m
    %:  warp:io
        (fall her our.bowl)
        (fall dek %base)
        ~
        %sing
        %x
        (fall cuse da+now.bowl)
        u.pax
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
