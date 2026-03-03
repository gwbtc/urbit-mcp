/-  mcp
^-  prompt:mcp
:*  'Commit desk'
    'commit-desk'
    '''
    Commit changes to a desk.
    '''
    :~  :*  'desk'
            'Name of the desk to commit (e.g. "mcp")'
            |
        ==
    ==
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    =/  dek  (~(get by args) 'desk')
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        """
        Commit this desk: {?~(dek "[the desk we're working on]" "%{(trip u.dek)}")}.
        If you get an error response, follow the stack trace
        and attempt to fix it. Consult the skills and resources
        you have to find out more about the Hoon error message
        if you don't recognize it. If you get a timeout,
        that means the commit was successful.
        """
    ==
==
