/-  mcp, spider
/+  io=strandio
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
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  hoon=(unit argument:tool:mcp)  (~(get by args) 'hoon')
  ?~  hoon
    (strand-fail %missing-argument ~)
  ?>  ?=([%string *] u.hoon)
  ;<    vax=vase
      bind:m
    (eval-hoon:io (ream p.u.hoon) ~)
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+p.u.hoon]
  ==
==
