/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'get-our-id'
  'Get the Urbit ID (@p) of this ship.'
  ~
  ~
  ^-  thread-builder:tool:mcp
  |=  *
  =/  m  (strand:spider ,vase)
  ^-  form:m
  ;<    =bowl:rand
      bind:m
    get-bowl:io
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+(crip "{<our.bowl>}")]
  ==
==
