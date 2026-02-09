/-  mcp, spider
/+  io=strandio, jut=json-utils
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
        String of Hoon code that should be a $-((map @t json) shed:khan), which must return MCP-compliant JSON..
        The simplest valid string is |=(* ^-(shed:khan =/(m (strand:spider ,vase) (pure:m !>((pairs:enjs:format ~[['type' s+'text'] ['text' s+'Success!']])))))).
        If you have an eval-thread-builder skill, consult that in full for important information about dependencies.
        The way dependencies are imported in the default tools is not the way you'll have to do it.
        '''
    ==
    ['hoon']~
    ^-  thread-builder:tool:mcp
    |=  args=(map @t json)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  jon=json  [%o args]
    =/  hoon-text=(unit @t)
      (~(deg jo:jut jon) /hoon so:dejs:format)
    ?~  hoon-text
      (strand-fail %missing-argument ~)
    ;<  =beak  bind:m  get-beak:io
    =/  vax=vase
      %+  slap
        !>  :*  mcp=mcp
                spider=spider
                strand=strand:spider
                io=io
                jut=jut
                strand-fail=strand-fail:strand:spider
                ..zuse
            ==
      (ream u.hoon-text)
    =/  =thread-builder:tool:mcp  !<(thread-builder:tool:mcp vax)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'Thread builder compiles!']
    ==
==
