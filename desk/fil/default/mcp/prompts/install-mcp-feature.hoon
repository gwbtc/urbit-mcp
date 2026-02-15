/-  mcp
^-  prompt:mcp
:*  'Install MCP feature'
    'install-mcp-feature'
    '''
    Install a single MCP feature from a beam URI by building and adding it to the mcp-server state.
    '''
    :~  :*  'ship'
            'The ship to get the feature from (Default: our ship)'
            |
        ==
        :*  'desk'
            'The desk containing the feature (Default: current desk)'
            |
        ==
        :*  'case'
            'The case (revision) to use (Default: now)'
            |
        ==
        :*  'path'
            'The path to the feature file.'
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
      ?~  ship-str
        "="
      (trip u.ship-str)
    =/  desk-part=tape
      ?~  desk-str  "="  (trip u.desk-str)
    =/  case-part=tape
      ?~  case-str  "="  (trip u.case-str)
    =/  beam-uri=tape
      "beam://{ship-part}/{desk-part}/{case-part}{(trip u.path-str)}"
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        """
        Use your install-mcp-feature tool to install
        the file at beam: {beam-uri}
        """
    ==
==
