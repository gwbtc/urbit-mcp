/-  mcp
^-  prompt:mcp
:*  'Nuke agent'
    'nuke-agent'
    '''
    Permanently wipe the state of a Gall agent.
    '''
    :~  :*  'agent'
            'Gall agent to nuke (e.g. "graph-store" to nuke %graph-store)'
            |
        ==
    ==
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    =/  agent  (~(get by args) 'agent')
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        ?~  agent
          """
          Use your nuke-agent tool to permanently wipe
          the state of the Gall agent we're working on right now.
          """
        """
        Use your nuke-agent tool to permanently wipe
        the state of the %{(trip u.agent)} Gall agent.
        """
    ==
==
