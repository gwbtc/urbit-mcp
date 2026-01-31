/-  mcp, spider
/+  server, strandio, json-utils
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
            |=  *
            =/  m  (strand:spider ,vase)
            ^-  form:m
            ;<    =bowl:rand
                bind:m
              get-bowl:strandio
            %-  pure:m
            !>  ^-  json
            %-  pairs:enjs:format
            :~  ['type' s+'text']
                ['text' s+(crip "{<our.bowl>}")]
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
    :~  :*  '/tools'
            'Available Tools'
            'List of available tools in JSON format'
            `'application/json'
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
::
::
::++  mcp-tools-list
::  |=  id=(unit json)
::  %-  pairs:enjs:format
::  %+  welp
::    ?~(id ~ ['id' u.id]~)
::  :~  ['jsonrpc' s+'2.0']
::      :-  'result'
::      %-  pairs:enjs:format
::      :~  ['tools' [%a tool-definitions]]
::      ==
::  ==
::
::  Convert parameter-type to JSON type string
::
::
::  Convert tool-def from lib/tools to MCP JSON format
::
::++  tool-def-to-mcp
::  |=  tool=tool-def:tools
::  ^-  json
::  ::  Convert parameters map to properties list
::  =/  properties=(map @t json)
::    %-  ~(run by parameters.tool)
::    |=  param=parameter-def:tools
::    %-  pairs:enjs:format
::    :~  ['type' s+(param-type-to-json type.param)]
::        ['description' s+description.param]
::    ==
::  ::  Convert required list to JSON array
::  =/  required-array=(list json)
::    (turn required.tool |=(f=@t s+f))
::  ::  Build MCP tool definition
::  %-  pairs:enjs:format
::  :~  ['name' s+name.tool]
::      ['description' s+description.tool]
::      :-  'inputSchema'
::      %-  pairs:enjs:format
::      :~  ['type' s+'object']
::          ['properties' [%o properties]]
::          ['required' [%a required-array]]
::      ==
::  ==
::
::  MCP Tool Registry - Converts all tools from lib/tools to MCP format
::
::++  tool-definitions
::  ^-  (list json)
::  (turn all-tools:tools tool-def-to-mcp)
::
::  Main MCP request handler
::
::++  handle-request
::  |=  jon=json
::  =/  m  (fiber:io ,(unit json))
::  ^-  form:m
::  ::  Parse JSON-RPC request using json-utils
::  =/  method=(unit json)  (~(get jo:json-utils jon) /method)
::  =/  id=(unit json)      (~(get jo:json-utils jon) /id)
::  ::  Route by JSON-RPC method
::  ?+    method
::    ::  Unknown method
::    (pure:m `(rpc-error rpc-method-not-found 'Method not found' id))
::    ::
::      [~ [%s %'initialize']]
::    ::  MCP initialization handshake
::    (pure:m `(mcp-initialize 'urbit-master' '1.0.0' id))
::    ::
::      [~ [%s %'notifications/initialized']]
::    ::  Client finished initialization - no response needed
::    (pure:m ~)
::    ::
::      [~ [%s %'tools/list']]
::    ::  Return list of available tools
::    (pure:m `(mcp-tools-list id))
::    ::
::      [~ [%s %'tools/call']]
::    ::  Execute tool call - extract nested params with jo
::    =/  tool-name=(unit json)  (~(get jo:json-utils jon) /params/name)
::    ?~  tool-name
::      (pure:m `(rpc-error rpc-invalid-params 'Missing tool name' id))
::    ?.  ?=([%s *] u.tool-name)
::      (pure:m `(rpc-error rpc-invalid-params 'Invalid tool name' id))
::    ::  Extract arguments as map
::    =/  arguments=(unit json)  (~(get jo:json-utils jon) /params/arguments)
::    ?~  arguments
::      (pure:m `(rpc-error rpc-invalid-params 'Missing arguments' id))
::    ?.  ?=([%o *] u.arguments)
::      (pure:m `(rpc-error rpc-invalid-params 'Invalid arguments' id))
::    ::  Extract optional chat-id from _meta and inject into arguments if present
::    =/  arguments-with-meta=(map @t json)
::      =/  meta=(unit json)  (~(get jo:json-utils jon) /params/'_meta'/'chat_id')
::      ?~  meta  p.u.arguments
::      (~(put by p.u.arguments) '_chat_id' u.meta)
::    ::  Delegate execution to lib/tools
::    ;<  result=tool-result:tools  bind:m  (execute-tool:tools p.u.tool-name arguments-with-meta)
::    ?-  -.result
::      %text   (pure:m `(mcp-text-result text.result id))
::      %error  (pure:m `(rpc-error rpc-internal-error message.result id))
::    ==
::  ==
--
