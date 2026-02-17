/-  mcp, spider
/+  server, libstrand=strand, io=strandio
=,  strand-fail=strand-fail:strand:spider
|%
::  MCP (Model Context Protocol) - JSON-RPC 2.0 Protocol Adapter
::  This library provides a thin protocol layer that:
::  - Converts tool definitions from lib/tools to MCP JSON-RPC format
::  - Handles MCP protocol-specific requests (initialize, tools/list, tools/call)
::  - Delegates tool execution to lib/tools
::
++  rpc
  |%
  ++  result
    |=  [result=json id=(unit json)]
    %-  pairs:enjs:format
    %+  welp
      ?~(id ~ ['id' u.id]~)
    :~  ['jsonrpc' s+'2.0']
        ['result' result]
    ==
  ++  error
    |%
    ++  code
    |%
    ++  parse-error       ~.-32700
    ++  invalid-request   ~.-32600
    ++  method-not-found  ~.-32601
    ++  invalid-params    ~.-32602
    ++  internal-error    ~.-32603
    --
    ++  make
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
    ++  parse
      |=  [message=@t id=(unit json)]
      (make parse-error:code message id)
    ++  request
      |=  [message=@t id=(unit json)]
      (make invalid-request:code message id)
    ++  method
      |=  [message=@t id=(unit json)]
      (make method-not-found:code message id)
    ++  params
      |=  [message=@t id=(unit json)]
      (make invalid-params:code message id)
    ++  internal
      |=  [message=@t id=(unit json)]
      (make internal-error:code message id)
    --
  --
::
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
        |=  =def:parameter:tool:mcp
        %-  pairs:enjs:format
        :~  ['type' s+(@t type.def)]
            ['description' s+desc.def]
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
++  prompt-messages-to-json
  |=  messages=(list message:prompt:mcp)
  ^-  json
  :-  %a
  %+  turn
    messages
  |=  =message:prompt:mcp
  ^-  json
  %-  pairs:enjs:format
  :~  ['role' s+role.message]
      :-  'content'
      %-  pairs:enjs:format
      :~  ['type' s+type.content.message]
          ?~  text.content.message
            ['text' s+'']
          ['text' s+u.text.content.message]
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
          |=  arg=argument:prompt:mcp
          ^-  json
          %-  pairs:enjs:format
          :~  ['name' s+name.arg]
              ['description' s+desc.arg]
              ['required' b+required.arg]
          ==
          :-  'icons'
          :-  %a
          %+  turn
            icons.prompt
          |=  =icon:prompt:mcp
          ^-  json
          %-  pairs:enjs:format
          :~  ['src' s+src.icon]
              ['mimeType' s+mime-type.icon]
              :-  'sizes'
              :-  %a
              %+  turn
                sizes.icon
              |=  size=@t
              [%s size]
          ==
      ==
  ==
--
