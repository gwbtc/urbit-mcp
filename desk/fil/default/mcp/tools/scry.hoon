/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'scry'
  '''
  Run a scry (read) to retrieve data from a vane or agent.
  Path format: /[vane letter][care]/[desk]/[path after beak]/[mark]
  The return type will always be JSON, and this read will fail if there is no
  mark conversion in the endpoint's desk from the endpoint's mark to JSON.
  '''
  %-  my
  :~  :-  'path'
      :-  %string
      '''
      The scry path (e.g. "/gx/mcp-server/tools/json"
      or "/cx/base/sys/kelvin").
      '''
  ==
  ~['path']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  pax=(unit argument:tool:mcp)  (~(get by args) 'path')
  ?~  pax
    ~|(%missing-path !!)
  ?>  ?=([%string @t] u.pax)
  ;<  result=json  bind:m
    (scry:io json (stab p.u.pax))
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+(crip "{<(en:json:html result)>}")]
  ==
==
