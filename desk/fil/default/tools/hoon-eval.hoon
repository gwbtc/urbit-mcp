/-  mcp, spider
/+  io=strandio, jut=json-utils
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'eval-hoon'
  '''
  Check correctness of a Hoon string.
  '''
  %-  my
  :~  :-  'hoon'
      :-  %string
      '''
      Any Hoon expression, such as `(add 2 2)`.
      '''
  ==
  ['hoon']~
  ^-  thread-builder:tool:mcp
  |=  args=(map @t json)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  args-json=json  [%o args]
  =/  hoon-text=(unit @t)
    (~(deg jo:jut args-json) /hoon so:dejs:format)
  ?~  hoon-text
    (strand-fail %missing-argument ~)
  ;<    vax=vase
      bind:m
    (eval-hoon:io (ream u.hoon-text) ~)
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+u.hoon-text]
  ==
==
