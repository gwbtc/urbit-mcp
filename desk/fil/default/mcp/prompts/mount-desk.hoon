/-  mcp
^-  prompt:mcp
:*  'Mount desk'
    'mount-desk'
    '''
    Mount a desk on this ship.
    '''
    :~  :*  'desk'
            'Desk to mount'
            &
        ==
    ==
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    =/  desk-str  (~(get by args) 'desk')
    ?~  desk-str
      ~|(%missing-desk !!)
    =/  desk-part=tape
      ?:  =("%" -.desk-str)
        "{(trip u.desk-str)}"
      "%{(trip u.desk-str)}"
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        """
        Use your mount-desk tool to mount
        the {desk-part} desk on this ship.
        """
    ==
==
