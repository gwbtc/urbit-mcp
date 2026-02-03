/-  mcp, spider
/+  io=strandio, ju=json-utils
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'khan-eval'
  'Evaluate a string of Hoon code to check if it is a valid $shed:khan. Useful for testing the body of a thread-builder gate for an MCP tool.'
  %-  my
  :~  :-  'hoon'
      :-  %string
      '''
      String of Hoon code that should be a $shed:khan.
      The simplest valid string is '=/  m  (strand ,vase)  (pure:m !>(%success))'.

      Your thread will be built against a subject with some dependencies:
        - /sur/mcp/hoon        - %mcp-server types
        - /sur/spider/hoon     - thread types
        - /lib/strand/hoon     - thread utilities library
        - /lib/strandio/hoon   - threads library
        - /lib/json-utils/hoon - json object parsing library

      You can access arms and types in those files as follows:
        - foo:mcp
        - foo:spider
        - foo:strand
        - foo:strandio
        - foo:json-utils

      If successful, this tool will return your Hoon string.
      If unsuccessful, this tool will return an error message and a stack trace.
      The error message will pertain to your code.
      The stack trace will point to the tool definition itself, not your code.
      '''
  ==
  ['hoon']~
  ^-  thread-builder:mcp
  |=  args=(map @t json)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  args-json=json  [%o args]
  =/  hoon-text=(unit @t)
    (fall (mole |.((~(deg jo:ju args-json) /hoon so:dejs:format))) ~)
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
  =/  =shed:khan  !<(shed:khan vax)
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+u.hoon-text]
  ==
==
