/-  mcp, spider
/+  io=strandio, jut=json-utils
^-  tool:mcp
:*  'mount-desk'
    '''
    Mount a desk on this ship.
    '''
    %-  my
    :~  :-  'desk'
        :-  %string
        '''
        Desk to mount (e.g. 'base' to mount %base).
        '''
    ==
    ['desk']~
    ^-  thread-builder:tool:mcp
    |=  args=(map @t json)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  args-json=json  [%o args]
    =/  desk-name=(unit @t)
      (~(deg jo:jut args-json) /desk so:dejs:format)
    ?~  desk-name  ~|(%missing-desk !!)
    =/  desk=@tas  (@tas u.desk-name)
    ;<  our=@p  bind:m  get-our:io
    ;<  now=@da  bind:m  get-time:io
    ;<  ~  bind:m
      (poke-our:io %hood %kiln-mount !>([(en-beam [our desk [%da now]] /) desk]))
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Mounted %{(trip u.desk-name)} desk")]
    ==
==
