/-  mcp
^-  prompt:mcp
:*  'Get file'
    'get-file'
    '''
    Fetch a Clay file (local or remote)
    '''
    :~  :*  'ship'
            'The Urbit ID of the ship this file is on (Default: our ship)'
            |
        ==
        :*  'desk'
            'The desk this file is in (Default: %base)'
            |
        ==
        :*  'case'
            'The $case (revision number or datetime) at which to access this file (Default: now)'
            |
        ==
        :*  'path'
            'The remaining filepath'
            &
        ==
    ==
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    =/  path-str  (~(get by args) 'path')
    ?~  path-str
      ~|(%missing-path !!)
    =/  ship-str  (~(get by args) 'ship')
    =/  desk-str  (~(get by args) 'desk')
    =/  case-str  (~(get by args) 'case')
    =/  ship-part=tape
      ?~  ship-str  "[our ship]"  "{(trip u.ship-str)}"
    =/  desk-part=tape
      ?~  desk-str  "[desk]"  " from %{(trip u.desk-str)}"
    =/  case-part=tape
      ?~  case-str  "[now]"  "{(trip u.case-str)}"
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        """
        Use your get-file tool to get {(trip u.path-str)}
        on {ship-part}'s {desk-part} at case {case-part}.
        Use your get-file tool to retrieve it.
        """
    ==
==
