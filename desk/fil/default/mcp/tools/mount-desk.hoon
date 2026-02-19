/-  mcp, spider
/+  io=strandio
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
    ~['desk']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  desk-arg=(unit argument:tool:mcp)  (~(get by args) 'desk')
    ?~  desk-arg
      ~|(%missing-desk !!)
    ?>  ?=([%string @t] u.desk-arg)
    =/  desk=@tas  (@tas p.u.desk-arg)
    ;<  our=@p   bind:m  get-our:io
    ;<  now=@da  bind:m  get-time:io
    ;<  ~  bind:m
      %:  poke-our:io
          %hood  %kiln-mount
          !>([(en-beam [our desk [%da now]] /) desk])
      ==
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Mounted %{(trip p.u.desk-arg)} desk")]
    ==
==
