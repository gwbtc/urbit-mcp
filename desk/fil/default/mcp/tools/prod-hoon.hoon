/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'prod-hoon'
  '''
  Run a Hoon string and return the result.
  '''
  %-  my
  :~  :-  'hoon'
      :-  %string
      '''
      Any Hoon expression, such as `(add 2 2)`.
      Expected result: '4'. All results will be text.
      '''
  ==
  ~['hoon']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  hoon-arg=(unit argument:tool:mcp)
    (~(get by args) 'hoon')
  ?~  hoon-arg
    (strand-fail %missing-argument ~)
  ?>  ?=([%string @t] u.hoon-arg)
    =/  vax=vase
      %+  slap
        !>  :*  mcp=mcp
                spider=spider
                strand=strand:spider
                io=io
                strand-fail=strand-fail:strand:spider
                ..zuse
            ==
      (ream p.u.hoon-arg)
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+p.u.hoon-arg]
  ==
==
