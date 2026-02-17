/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'toggle-permissions'
    '''
    Make a node in the Clay filesystem public or private.
    Publish a desk as an app by making the whole desk public.
    '''
    %-  my
    :~  :-  'desk'
        :-  %string
        '''
        Target desk.
        '''
        :-  'path'
        :-  %string
        '''
        Target filepath. If /, the whole desk will be
        public for anyone to read and install. If e.g. /fil, 
        only the /fil directory in the desk will be public.
        '''
        :-  'permissions'
        :-  %boolean
        '''
        True is totally public, and false is
        private to the host ship.
        '''
    ==
    ~['desk' 'path' 'permissions']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  dek=(unit argument:tool:mcp)  (~(get by args) 'desk')
    =/  pax=(unit argument:tool:mcp)  (~(get by args) 'path')
    =/  per=(unit argument:tool:mcp)  (~(get by args) 'permissions')
    ?~  dek
      ~|(%missing-desk !!)
    ?~  pax
      ~|(%missing-path !!)
    ?~  per
      ~|(%missing-permission-setting !!)
    ?>  ?=([%string @t] u.dek)
    ?>  ?=([%boolean ?] u.per)
    ?>  ?=([%string @t] u.pax)
    ;<  ~  bind:m
      %:  poke-our:io
          %hood
          %kiln-permission
          !>([(@tas p.u.dek) (stab p.u.pax) p.u.per])
      ==
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        :-  'text'
        :-  %s
        ?:  =('/' p.u.pax)
            ?:  p.u.per
              (crip "Made {(trip p.u.dek)} public")
            (crip "Made {(trip p.u.dek)} private")
        ?:  p.u.per
          (crip "Made {(trip p.u.dek)}'s {(trip p.u.pax)} public")
        (crip "Made {(trip p.u.dek)}'s {(trip p.u.pax)} private")
    ==
==

