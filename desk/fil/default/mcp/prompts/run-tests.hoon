/-  mcp
^-  prompt:mcp
:*  'Run tests'
    'run-tests'
    '''
    Run unit tests and/or integration tests, given a desk and a path prefix.
    '''
    :~  :*  'desk'
            'Desk name to run tests on (e.g. "base" or "mcp-server")'
            &
        ==
        :*  'path'
            'Path prefix for tests to run (e.g. "/tests" or "/tests/lib")'
            &
        ==
    ==
    ~
    |=  args=(map name:argument:prompt:mcp @t)
    ^-  (list message:prompt:mcp)
    =/  desk-str  (~(get by args) 'desk')
    ?~  desk-str
      ~|(%missing-desk !!)
    =/  path-str  (~(get by args) 'path')
    ?~  path-str
      ~|(%missing-path !!)
    =/  desk-part=tape
      ?:  =("%" -.desk-str)
        "{(trip u.desk-str)}"
      "%{(trip u.desk-str)}"
    =/  path-part=tape
      "{(trip u.path-str)}"
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        """
        Use your run-tests tool to run tests on
        the {desk-part} desk at path {path-part}.
        """
    ==
==
