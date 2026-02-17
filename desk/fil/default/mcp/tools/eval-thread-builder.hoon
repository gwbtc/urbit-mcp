/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'eval-thread-builder'
    '''
    Check if a Hoon string is a valid $thread-builder:mcp.
    '''
    %-  my
    :~  :-  'hoon'
        :-  %string
        '''
        String of Hoon code that should be a $-((map name:parameter:tool:mcp argument:tool:mcp) shed:khan), which must return MCP-compliant JSON..
        The simplest valid string is |=(args=(map name:parameter:tool:mcp argument:tool:mcp) ^-(shed:khan =/(m (strand:spider ,vase) (pure:m !>((pairs:enjs:format ~[['type' s+'text'] ['text' s+'Success!']])))))).
        If you have an eval-thread-builder skill, consult that in full for important information about dependencies.
        The way dependencies are imported in the default tools is not the way you'll have to do it.
        '''
    ==
    ['hoon']~
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  hoon-arg=(unit argument:tool:mcp)  (~(get by args) 'hoon')
    ?~  hoon-arg
      (strand-fail %missing-argument ~)
    ?>  ?=([%string @t] u.hoon-arg)
    ;<  =beak  bind:m  get-beak:io
    =/  vax=vase
      %+  slap
        !>  :*  mcp=mcp
                spider=spider
                strand=strand:spider
                io=io
                strand-fail=strand-fail:strand:spider
                ..zuse
            ==
      (ream p.u.hoon-arg)
    =/  =thread-builder:tool:mcp
      !<(thread-builder:tool:mcp vax)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'Thread builder compiles!']
    ==
==
