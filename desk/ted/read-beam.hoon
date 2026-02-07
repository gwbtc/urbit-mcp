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
^-  thread:spider
|=  arg=vase
=/  =beam  (need !<((unit beam) arg))
^-  shed:khan
=/  m  (strand:spider ,vase)
^-  form:m
;<  =riot:clay  bind:m
  (warp:io p.beam q.beam ~ %sing %x r.beam s.beam)
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
