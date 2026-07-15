/-  mcp
^-  prompt:mcp
:*  'Test build'
    'mcp/test-build'
    '''
    Compile a Hoon source file and report its complete dependency build error.
    '''
    :~  :*  'desk'
            'Desk containing the source file (e.g. "base" or "mcp")'
            &
        ==
        :*  'path'
            'Clay source path including its mark (e.g. "/lib/foo/hoon")'
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
    :~  :-  %user
        :-  %text
        %-  some
        %-  crip
        """
        Use your test-build tool to compile {(trip u.path-str)} on the
        {desk-part} desk. If it fails, report the complete compiler and
        dependency trace returned by the tool.
        """
    ==
==
