/-  mcp
^-  prompt:mcp
:*  'Revive agent'
    'revive-agent'
    '''
    Revive (re-initialize) a nuked Gall agent on this ship.
    '''
    :~  :*  'agent'
            'Desk name to revive (e.g. "hark" to revive %hark)'
            &
        ==
    ==
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    =/  agent  (~(get by args) 'agent')
    :~  :-  %user
        :-  %text
        %-  some
        ?~  agent
         '''
         Use your revive-agent tool to revive the agent we're working on.
         '''
        %-  crip
        """
        Use your revive-agent tool to revive %{(trip u.agent)}.
        """
    ==
==
