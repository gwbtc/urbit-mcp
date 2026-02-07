/-  mcp, spider
/+  io=strandio, jut=json-utils
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'eval-thread-builder'
    '''
    Evaluate a string of Hoon code to check if it's a valid $thread-builder:mcp.
    A $thread-builder is a Hoon gate which takes a (map @t json) and returns $shed:khan.
    Use this to test the body of a new MCP tool before adding it to the %mcp-server.
    '''
    %-  my
    :~  :-  'hoon'
        :-  %string
        '''
        String of Hoon code that should be a $-((map @t json) shed:khan).
        The simplest valid string is |=(* ^-(shed:khan =/(m (strand:spider ,vase) (pure:m !>(%success))))).
        Look at the Urbit MCP Tool examples linked in your MCP Resources for examples of working thread-builders.
        Note that those example tools have namespaced dependencies in ways your tool cannot.
        Your $thread-builder gate will be built against a Hoon subject with some dependencies:
          - /sur/mcp/hoon        - %mcp-server types
          - /sur/spider/hoon     - thread types
          - /lib/strand/hoon     - thread utilities library
          - /lib/strandio/hoon   - threads library
          - /lib/json-utils/hoon - json object parsing library
        You can access arms and types in your $thread-builder code as follows:
          - foo:mcp         (no alias in examples)
          - foo:spider      (no alias in examples)
          - foo:strand      (foo:libstrand in examples)
          - foo:strandio    (foo:io in examples)
          - foo:json-utils  (foo:jut in examples)
        If successful, this tool will return a success message.
        If unsuccessful, this tool will return an error message and a stack trace.
        The error message will pertain to your code.
        The stack trace will point to this tool definition file, not your code.
        '''
    ==
    ['hoon']~
    ^-  thread-builder:mcp
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
    =/  bez=(list beam)
      :~  [beak /sur/mcp/hoon]
          [beak /lib/strand/hoon]
          [beak /sur/spider/hoon]
          [beak /lib/strandio/hoon]
          [beak /lib/json-utils/hoon]
      ==
    ;<    vax=vase
        bind:m
      (eval-hoon:io (ream u.hoon-text) bez)
    =/  =thread-builder:mcp  !<(thread-builder:mcp vax)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+'Thread builder compiles!']
    ==
==
