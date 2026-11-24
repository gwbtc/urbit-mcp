::  %mcp-proxy: remote mcp servers whose tools %mcp-server serves
::
|%
::
::  foreign ids need not fit @tas; encode with (scot %t id)
::  wherever an id enters a wire or path
+$  server-id  @t
::
::  a client-facing name; only tools for now, but could
::  later name resources, templates and so on
+$  feature    @t
+$  header     [key=@t value=@t]
::
::  .tools: tool json from the remote's tools/list,
::  each name rewritten to <server-id>/<tool-name>
+$  remote-mcp-server
  $:  url=@t
      headers=(list header)
      tools=(list json)
  ==
::
+$  state-0
  $:  %0
      servers=(map server-id remote-mcp-server)
      ::  full client-facing names, grouped by server;
      ::  (local-key our) holds blocked local tools
      blocked=(map server-id (set feature))
  ==
::
+$  action
  $%  [%add-mcp-server id=server-id url=@t headers=(list header)]
      [%delete-mcp-server id=server-id]
      ::  ~ refreshes all
      [%refresh-mcp-server id=(unit server-id)]
      [%block-tool id=server-id tool=feature]
      [%unblock-tool id=server-id tool=feature]
      ::  %mcp-server only; the result goes to /call/[uuid]
      [%call-tool uuid=@ta tool=feature arguments=json]
  ==
::
::  the outcome of a remote tools/call
+$  result
  $%  [%result =json]
      [%error code=@ta message=@t data=(unit json)]
  ==
::
+$  update
  $%  [%tools-changed ~]
      [%tool-result =result]
  ==
::
::  +local-key: blocklist key for %mcp-server's own tools,
::  our @p without the ~ and a -urbit-mcp suffix
++  local-key
  |=  our=@p
  ^-  server-id
  (cat 3 (rsh [3 1] (scot %p our)) '-urbit-mcp')
--
