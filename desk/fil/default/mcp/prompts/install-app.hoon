/-  mcp
^-  prompt:mcp
:*  'Install app'
    'install-app'
    '''
    Install a desk (local or remote).
    '''
    :~  :*  'ship'
            'App host'
            |
        ==
        :*  'desk'
            'App to install'
            &
        ==
    ==
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    =/  desk-str  (~(get by args) 'desk')
    ?~  desk-str
      ~|(%missing-desk !!)
    =/  ship-str  (~(get by args) 'ship')
    =/  desk-part=tape
      ?:  =("%" -.desk-str)
        "{(trip u.desk-str)}"
      "%{(trip u.desk-str)}"
    =/  ship-part=tape
      ?~  ship-str
        "[our ship]"
      "{(trip u.ship-str)}"
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        """
        Use your install-app tool to install {desk-part} from {ship-part}.
        """
    ==
==
