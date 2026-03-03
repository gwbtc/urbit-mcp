/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'install-app'
    '''
    Install a desk (local or remote).
    '''
    %-  my
    :~  :-  'ship'
        :-  %string
        '''
        Urbit ship from which to install this desk.
        If you create a new desk, you must install it to run it on your ship.
        (Default: our own ship.)
        '''
        :-  'desk'
        :-  %string
        '''
        App (desk) to install (e.g. 'mcp' to install %mcp).
        '''
    ==
    ~['desk']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  desk-arg=(unit argument:tool:mcp)
      (~(get by args) 'desk')
    ?~  desk-arg
      (strand-fail %missing-desk ~)
    ?>  ?=([%string @t] u.desk-arg)
    =/  dek=@tas  (@tas p.u.desk-arg)
    ;<  our=@p  bind:m  get-our:io
    =/  ship-arg=(unit argument:tool:mcp)
      (~(get by args) 'ship')
    =/  who=(unit @t)
      ?~  ship-arg  ~
      ?>  ?=([%string @t] u.ship-arg)
      `p.u.ship-arg
    ;<  ~  bind:m
      %:  poke-our:io
          %hood
          %kiln-install
          !>([dek ?~(who our (@p (slav %p u.who))) dek])
      ==
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        :-  'text'
        :-  %s
        %-  crip
        """
        Installing %{(trip dek)} from {?~(who (trip (@t (scot %p our))) (trip u.who))}.
        """
    ==
==
