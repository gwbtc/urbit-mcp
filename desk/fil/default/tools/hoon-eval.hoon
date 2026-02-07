/-  mcp, spider
/+  io=strandio, jut=json-utils
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'hoon-eval'
  '''
  Evaluate arbitrary Hoon to test for correctness.
  Will not return the result of the Hoon expression.
  '''
  %-  my
  :~  :-  'hoon'
      :-  %string
      '''
      Any Hoon expression, such as `(add 2 2)`.
      Note: this Hoon will be run against the Arvo kernel itself.
      That means you'll need to import your own dependencies (e.g. strandio).
      If successful, this tool will return your Hoon string.
      If unsuccessful, this tool will return an error message and a stack trace.
      The error message will pertain to your code.
      The stack trace will point to the tool definition itself, not your code.
      '''
  ==
  ['hoon']~
  ^-  thread-builder:mcp
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
