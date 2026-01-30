/-  mcp
/+  server, json-utils
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
    :~  :*  'test'
            'this is a test mcp tool'
            parameters:*tool:mcp
            required:*tool:mcp
            *card:agent:gall
        ==
    ==
  ++  resources
    ^-  (list resource:mcp)
    *(list resource:mcp)
  ++  prompts
    ^-  (list prompt:mcp)
    *(list prompt:mcp)
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
++  mcp-tools-list
  |=  [server-name=@t version=@t id=(unit json)]
  ^-  json
  %-  pairs:enjs:format
  %+  welp
    ?~(id ~ ['id' u.id]~)
  :~  ['jsonrpc' s+'2.0']
      :-  'result'
      %-  pairs:enjs:format
      ::  XX needs to be up-to-date with whatever
      ::     the MCP client says its own version is
      :~  ['protocolVersion' s+'2024-11-05']
          :-  'capabilities'
          %-  pairs:enjs:format
          :~  :-  'tools'
              ::  XX change listChanged to %.y once
              ::     real-time notifs are implemented
              ::  %-  pairs:enjs:format
              ::  :~  ['listChanged' b+%.n]
              :-  %a
              %+  turn
                tools:defaults
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
              :-  'resources'
              ::  XX change listChanged to %.y once real-time
              ::     notifications are implemented
              ::  XX subscribe %.y once we can %watch resources
              ::     can't use resources for scry paths AND
              ::     watch paths until we have sticky-scry
              ::     in which case we can interpret the
              ::     subscribe request as a %watch or
              ::     sticky-scry as appropriate
              %-  pairs:enjs:format
              :~  ['subscribe' b+%.n]
                  ['listChanged' b+%.n]
              ==
              :-  'prompts'
              ::  XX change listChanged to %.y once
              ::     real-time notifs are implemented
              (pairs:enjs:format ~[['listChanged' b+%.n]])
          ==
          :-  'serverInfo'
          %-  pairs:enjs:format
          :~  ['name' s+server-name]
              ['version' s+version]
          ==
      ==
  ==
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
