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
::
++  mark-mime
  |=  =mark
  ^-  @t
  ?+  mark  'application/octet-stream'
    %css   'text/css'
    %hoon  'text/hoon'
    %html  'text/html'
    %js    'text/javascript'
    %json  'application/json'
    %md    'text/markdown'
    %txt   'text/plain'
    %xml   'application/xml'
  ==
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
:~  ['uri' s+(crip (welp "beam://" (spud (en-beam beam))))]
    ::  internal use only, replaced with mimeType in the agent
    ['mime-type' s+(mark-mime (rear s.beam))]
    :-  'text'
    :-  %s
    ?~  riot
      'Failed to fetch file.'
    %-  crip
    %-  print-tang-to-wain
    %-  pretty-file:pf
    !<(noun q.r.u.riot)
==
