/-  mcp
^-  prompt:mcp
:*  'get-our-id'
    'Get Our Urbit ID'
    'Retrieve the Urbit ID (@p) of this ship'
    ~
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    :~  :-  %user
        :-  %text
        %-  some
        '''
        Use your get-our-id tool to get the Urbit ID of this ship.
        '''
    ==
==
