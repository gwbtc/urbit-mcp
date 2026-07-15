/-  mcp, spider
/+  db=builder, io=strandio
=>
|%
++  print-tang
  |=  =tang
  ^-  @t
  %-  of-wain:format
  %-  zing
  %+  turn  tang
  |=  =tank
  %+  turn  (wash [0 80] tank)
  |=  =tape
  (crip tape)
--
::
^-  tool:mcp
:*  'mcp/test-build'
    '''
    Compile a Hoon source file and return any build errors.
    The build reads source through Clay at the current revision.
    '''
    %-  my
    :~  :-  'desk'
        :-  %string
        '''
        Desk containing the source file (e.g. "base" or "mcp").
        '''
        :-  'path'
        :-  %string
        '''
        Clay source path including its mark (e.g. "/lib/foo/hoon").
        '''
    ==
    ~['desk' 'path']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  desk-arg=(unit argument:tool:mcp)  (~(get by args) 'desk')
    ?~  desk-arg
      (pure:m !>([%error %missing-desk ~]))
    ?>  ?=([%string @t] u.desk-arg)
    =/  path-arg=(unit argument:tool:mcp)  (~(get by args) 'path')
    ?~  path-arg
      (pure:m !>([%error %missing-path ~]))
    ?>  ?=([%string @t] u.path-arg)
    ;<  =bowl:rand  bind:m  get-bowl:io
    =/  desk=@tas  (@tas p.u.desk-arg)
    =/  target=path  (stab p.u.path-arg)
    =/  result=(each vase tang)
      (~(build db [our.bowl desk now.bowl]) target)
    ?-  -.result
      %|
        %-  pure:m
        !>  ^-  response:tool:mcp
        [%error (print-tang p.result) ~]
      %&
        %-  pure:m
        !>  ^-  response:tool:mcp
        :-  %result
        :-  %unstructured
        :~  :-  %text
            (crip "Built {(spud target)} on %{(trip desk)} successfully.")
        ==
    ==
==
