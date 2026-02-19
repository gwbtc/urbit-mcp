/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'poke-our-agent'
  '''
  Poke a Gall agent with data of a specified mark.
  '''
  %-  my
  :~  :-  'agent'
      :-  %string
      '''
      The name of the Gall agent to poke (e.g. 'hood').
      '''
  ::
      :-  'mark'
      :-  %string
      '''
      The mark of the poke (e.g. 'helm-pass').
      '''
  ::
      :-  'data'
      :-  %string
      '''
      Hoon expression of the type expected for this poke.
      '''
  ==
  ~['agent' 'mark' 'data']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  ant=(unit argument:tool:mcp)  (~(get by args) 'agent')
  =/  mar=(unit argument:tool:mcp)  (~(get by args) 'mark')
  =/  dat=(unit argument:tool:mcp)  (~(get by args) 'data')
  ?~  ant  (strand-fail %missing-agent ~)
  ?~  mar  (strand-fail %missing-mark ~)
  ?~  dat  (strand-fail %missing-data ~)
  ?>  ?=([%string *] u.ant)
  ?>  ?=([%string *] u.mar)
  ?>  ?=([%string *] u.dat)
  ;<  ~  bind:m
    %:  poke-our:io
        (@tas p.u.ant)
        (@tas p.u.mar)
        (slap !>(..zuse) (ream p.u.dat))
    ==
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+(crip "Successfully poked {<(trip p.u.ant)>} with {<(trip p.u.mar)>}")]
  ==
==
