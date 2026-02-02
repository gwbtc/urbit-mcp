/-  mcp, spider
/+  server, io=strandio, json-utils
=,  strand-fail=strand-fail:strand:spider
|%
::  MCP (Model Context Protocol) - JSON-RPC 2.0 Protocol Adapter
::  This library provides a thin protocol layer that:
::  - Converts tool definitions from lib/tools to MCP JSON-RPC format
::  - Handles MCP protocol-specific requests (initialize, tools/list, tools/call)
::  - Delegates tool execution to lib/tools
::
::  JSON-RPC 2.0 error codes
::
++  rpc-parse-error       ~.-32700
++  rpc-invalid-request   ~.-32600
++  rpc-method-not-found  ~.-32601
++  rpc-invalid-params    ~.-32602
++  rpc-internal-error    ~.-32603
::  JSON-RPC helper functions
::
++  defaults
  |%
  ++  tools
    ^-  (list tool:mcp)
    :~  :*  'get our Urbit ID'
            'get the Urbit ID / @p of this ship'
            ~
            ~
            ^-  thread-builder:mcp
            |=  *
            =/  m  (strand:spider ,vase)
            ^-  form:m
            ;<    =bowl:rand
                bind:m
              get-bowl:io
            %-  pure:m
            !>  ^-  json
            %-  pairs:enjs:format
            :~  ['type' s+'text']
                ['text' s+(crip "{<our.bowl>}")]
            ==
        ==
        :*  'Commit desk'
            'Commit code changes to a desk. If this errors with a timeout, there are no changes to commit.'
            (my ['desk' [%string (crip "desk name (e.g. 'base' to commit the %base desk)")]]~)
            ['desk']~
            ^-  thread-builder:mcp
            =>
            |%
            ++  print-tang-to-wain
              |=  =tang
              ^-  wain
              %-  zing
              %+  turn
                tang
              |=  =tank
              %+  turn
                (wash [0 80] tank)
              |=  =tape
              (crip tape)
            --
            |=  args=(map @t json)
            ^-  shed:khan
            =/  m  (strand:spider ,vase)
            ^-  form:m
            =/  args-json=json  [%o args]
            =/  desk-name=(unit @t)
              (fall (mole |.((~(deg jo:json-utils args-json) /desk so:dejs:format))) ~)
            ?~  desk-name  ~|(%missing-desk !!)
            =/  desk=@tas  (@tas u.desk-name)
            ;<  ~  bind:m
              (send-raw-card:io [%pass /dill-logs %arvo %d %logs `~])
            ;<  ~  bind:m
              (poke-our:io %hood %kiln-commit !>([desk %.n]))
            ;<  [wire =sign-arvo]  bind:m
              ((set-timeout:io ,[wire sign-arvo]) ~s2 take-sign-arvo:io)
            ?>  ?=([%dill %logs *] sign-arvo)
            ;<  ~  bind:m
              (send-raw-card:io [%pass /dill-logs %arvo %d %logs ~])
            =/  [%dill %logs =told:dill]  sign-arvo
            ?-  told
              [%crud *]
              %-  pure:m
              !>  ^-  json
              %-  pairs:enjs:format
              :~  ['type' s+'text']
                  ['text' s+(crip "{<[%error p.told (print-tang-to-wain q.told)]>}")]
              ==
            ::
              [%talk *]
              ~&  >>  %talk
              ~&  >>  p.told
              %-  pure:m
              !>  ^-  json
              %-  pairs:enjs:format
              :~  ['type' s+'text']
                  ['text' s+(crip "{<[%talk (print-tang-to-wain p.told)]>}")]
              ==
            ::
              [%text *]
              ::  XX stub, would be better to return list of changed files
              ::     need to get any more %text gifts that come in from Dill
              %-  pure:m
              !>  ^-  json
              %-  pairs:enjs:format
              :~  ['type' s+'text']
                  ['text' s+'Commit successful!']
              ==
            ==
        ==
        :*  'Add MCP tool'
            'Add a new MCP tool to the %mcp-server agent.'
            %-  my
            :~  ['name' [%string 'The name of your MCP tool.']]
                ['desc' [%string 'The description of your MCP tool.']]
                ['parameters' [%object 'The parameters your MCP tool will take.']]
                ['required' [%array 'The non-optional parameters your MCP tool needs.']]
                ::  XX explain helper cores for reusable functions
                ::  XX explain what's available in the subject
                ['thread-builder' [%string 'A Hoon gate $-((map @t json) ,vase).']]
            ==
            ~['name' 'desc' 'parameters' 'required' 'thread-builder']
            ^-  thread-builder:mcp
            |=  args=(map @t json)
            ^-  shed:khan
            =/  m  (strand:spider ,vase)
            ^-  form:m
            =/  args-json=json  [%o args]
            =/  nam=(unit @t)
              (fall (mole |.((~(deg jo:json-utils args-json) /name so:dejs:format))) ~)
            =/  des=(unit @t)
              (fall (mole |.((~(deg jo:json-utils args-json) /desc so:dejs:format))) ~)
            =/  parameters=(unit (map @t json))
              ?~  param-json=(~(get jo:json-utils args-json) /parameters)  ~
              ?.  ?=([%o *] u.param-json)  ~
              `p.u.param-json
            =/  required=(unit (list @t))
              (fall (mole |.((~(deg jo:json-utils args-json) /required (ar so):dejs:format))) ~)
            =/  thread-builder=(unit @t)
              (fall (mole |.((~(deg jo:json-utils args-json) /thread-builder so:dejs:format))) ~)
            ?~  nam  ~|(%missing-name !!)
            ?~  des  ~|(%missing-desc !!)
            ?~  parameters  ~|(%missing-parameters !!)
            ?~  required  ~|(%missing-required !!)
            ?~  thread-builder  ~|(%missing-thread-builder !!)
            =/  req=(list @t)  u.required
            ;<  =beak  bind:m  get-beak:io
            =/  bez=(list beam)
              :~  [beak /sur/mcp/hoon]
                  [beak /sur/spider/hoon]
                  [beak /lib/strandio/hoon]
                  [beak /lib/json-utils/hoon]
              ==
            ;<    vax=vase
                bind:m
              (eval-hoon:io (ream u.thread-builder) bez)
            =/  par=(map name:mcp parameter-def:mcp)
              %-  ~(gas by *(map name:mcp parameter-def:mcp))
              %+  turn
                ~(tap by u.parameters)
              |=  [name=@t =json]
              ^-  [name:mcp parameter-def:mcp]
              ?.  ?=([%o *] json)
                ~|(%invalid-parameter-definition !!)
              :-  name
              =/  type-text=(unit @t)
                (fall (mole |.((~(deg jo:json-utils json) /type so:dejs:format))) ~)
              =/  desc-text=(unit @t)
                (fall (mole |.((~(deg jo:json-utils json) /description so:dejs:format))) ~)
              ?~  type-text
                ~|(%missing-parameter-type !!)
              ?~  desc-text
                ~|(%missing-parameter-description !!)
              [(parameter-type:mcp u.type-text) u.desc-text]
            ;<  our=ship  bind:m  get-our:io
            ;<  ~  bind:m
              %-  send-raw-card:io
              :*  %pass   /add-tool
                  %agent  [our %mcp-server]
                  %poke  %add-mcp-tool
                  !>([u.nam u.des par req !<(thread-builder:mcp vax)])
              ==
            ;<  ~  bind:m  (take-poke-ack:io /add-tool)
            %-  pure:m
            !>  ^-  json
            %-  pairs:enjs:format
            :~  ['type' s+'text']
                ['text' s+'Tool added!']
            ==
        ==
        :*  'khan-eval'
            'Evaluate a string of Hoon code to check if it is a valid $shed:khan. Useful for testing the body of a thread-builder gate for an MCP tool.'
            %-  my
            :~  :-  'hoon'
                :-  %string
                '''
                String of Hoon code that should be a $shed:khan.
                The simplest valid string is '=/  m  (strand ,vase)  (pure:m !>(%success))'.
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
              (fall (mole |.((~(deg jo:json-utils args-json) /hoon so:dejs:format))) ~)
            ?~  hoon-text
              (strand-fail %missing-argument ~)
            ;<  =beak  bind:m  get-beak:io
            =/  bez=(list beam)
              :~  [beak /sur/mcp/hoon]
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
        :*  'hoon-eval'
            '''
            Evaluate arbitrary Hoon to test for correctness.
            Will not return the result of the Hoon expression.
            '''
            %-  my
            :~  :-  'hoon'
                :-  %string
                '''
                Any Hoon expression, such as `(add 2 2)`.
                Note: this Hoon will be run against the Arvo kernel itself.
                That means you'll need to import your own dependencies (e.g. strandio).
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
              (fall (mole |.((~(deg jo:json-utils args-json) /hoon so:dejs:format))) ~)
            ?~  hoon-text
              (strand-fail %missing-argument ~)
            ;<    vax=vase
                bind:m
              (eval-hoon:io (ream u.hoon-text) ~)
            %-  pure:m
            !>  ^-  json
            %-  pairs:enjs:format
            :~  ['type' s+'text']
                ['text' s+u.hoon-text]
            ==
        ==
    ==
::    :~  :*  'set Behn timer'
::            'set a Behn timer for testing purposes'
::            (my ['duration' [%string 'relative duration from now in Urbit @dr format: ~s1, ~m1, ~h1, ~d1, ~w1, ~y1']]~)
::            ['duration']~
::            ^-  shed:khan
::            ::  XX  pseudocode
::            %-  hoon-eval
::            """
::            =/  m  (strand:strandio ,vase)
::            """
::            :~  '[%pass /0x0/1 %arvo %b %wait (add now.bowl {<duration>})]'
::            ==
::        ==
::    ==
  ++  resources
    ^-  (list resource:mcp)
    :~  :*  'https://docs.urbit.org/llms.txt'
            'Urbit Docs llms.txt'
            'LLM-readable sitemap of https://docs.urbit.org content'
            `'text/markdown'
        ==
    ==
  ++  prompts
    ^-  (list prompt:mcp)
    :~  :*  'get-urbit-id'
            'Get Our Urbit ID'
            'Retrieve the Urbit ID (@p) of this ship'
            ~
        ==
    ==
  --
++  rpc-error
  |=  [code=@ta message=@t id=(unit json)]
  ^-  json
  %-  pairs:enjs:format
  %+  welp
    ?~(id ~ ['id' u.id]~)
  :~  ['jsonrpc' s+'2.0']
      :-  'error'
      %-  pairs:enjs:format
      :~  ['code' n+code]
          ['message' s+message]
      ==
  ==
::
++  rpc-result
  |=  [result=json id=(unit json)]
  %-  pairs:enjs:format
  %+  welp
    ?~(id ~ ['id' u.id]~)
  :~  ['jsonrpc' s+'2.0']
      ['result' result]
  ==
::  MCP-specific response helpers
::
++  mcp-text-result
  |=  [text=@t id=(unit json)]
  %-  pairs:enjs:format
  %+  welp
    ?~(id ~ ['id' u.id]~)
  :~  ['jsonrpc' s+'2.0']
      :-  'result'
      %-  pairs:enjs:format
      :~  :-  'content'
          :-  %a
          :~  %-  pairs:enjs:format
              :~  ['type' s+'text']
                  ['text' s+text]
              ==
          ==
      ==
  ==
::
++  param-type-to-json
  |=  type=parameter-type:mcp
  ^-  @t
  ?-  type
    %string   'string'
    %number   'number'
    %boolean  'boolean'
    %array    'array'
    %object   'object'
  ==
::
++  mcp-tools-to-json
  |=  tool-set=(set tool:mcp)
  ^-  json
  %-  pairs:enjs:format
  :~  :-  'tools'
      :-  %a
      %+  turn
        ~(tap in tool-set)
      |=  =tool:mcp
      ^-  json
      =/  properties=(map @t json)
        %-  ~(run by parameters.tool)
        |=  param=parameter-def:mcp
        %-  pairs:enjs:format
        :~  ['type' s+(param-type-to-json parameter-type.param)]
            ['description' s+desc.param]
        ==
      ::  Convert required list to JSON array
      =/  required-array=(list json)
        (turn required.tool |=(f=@t s+f))
      %-  pairs:enjs:format
      :~  ['name' [%s name.tool]]
          ['description' [%s desc.tool]]
          :-  'inputSchema'
          %-  pairs:enjs:format
          :~  ['type' [%s 'object']]
              ['properties' [%o properties]]
              ['required' [%a required-array]]
          ==
      ==
  ==
::
++  mcp-resources-to-json
  |=  resource-set=(set resource:mcp)
  ^-  json
  %-  pairs:enjs:format
  :~  :-  'resources'
      :-  %a
      %+  turn
        ~(tap in resource-set)
      |=  =resource:mcp
      ^-  json
      %-  pairs:enjs:format
      %+  welp
        :~  ['uri' s+uri.resource]
            ['name' s+name.resource]
            ['description' s+desc.resource]
        ==
      ?~  mime-type.resource  ~
      :~  ['mimeType' s+u.mime-type.resource]
      ==
  ==
::
++  mcp-prompts-to-json
  |=  prompt-set=(set prompt:mcp)
  ^-  json
  %-  pairs:enjs:format
  :~  :-  'prompts'
      :-  %a
      %+  turn
        ~(tap in prompt-set)
      |=  =prompt:mcp
      ^-  json
      %-  pairs:enjs:format
      :~  ['name' s+name.prompt]
          ['title' s+title.prompt]
          ['description' s+desc.prompt]
          :-  'arguments'
          :-  %a
          %+  turn
            arguments.prompt
          |=  arg=prompt-argument:mcp
          ^-  json
          %-  pairs:enjs:format
          %+  welp
            :~  ['name' s+name.arg]
                ['description' s+desc.arg]
                ['required' b+required.arg]
            ==
          ?~  parameter-type.arg  ~
          :~  ['type' s+(param-type-to-json u.parameter-type.arg)]
          ==
      ==
  ==
--
