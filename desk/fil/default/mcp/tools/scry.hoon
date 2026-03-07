/-  mcp, spider
/+  io=strandio, libstrand=strand
=,  strand-fail=strand-fail:libstrand
^-  tool:mcp
:*  'scry-agent'
  '''
  Run a %gx scry (read) to retrieve data from a Gall agent.
  The endpoint must return JSON for this tool to work.
  '''
  %-  my
  :~  :-  'agent'
      :-  %string
      '''
      The Gall agent to scry.
      '''
      :-  'path'
      :-  %string
      '''
      The scry path (e.g. "/tools/json").
      '''
  ==
  ~['agent' 'path']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  gen=(unit argument:tool:mcp)  (~(get by args) 'agent')
  ?~  gen  ~|(%missing-agent !!)
  =/  pax=(unit argument:tool:mcp)  (~(get by args) 'path')
  ?~  pax  ~|(%missing-path !!)
  ?>  ?=([%string @t] u.gen)
  ?>  ?=([%string @t] u.pax)
  ::  slap path to handle interpolation, +scot etc.
  =/  =path  !<(path (slap !>(.) (ream p.u.pax)))
  ?.  =(%json (rear path))
    (strand-fail %scry-path-must-return-json ~)
  ;<  =bowl:spider  bind:m  get-bowl:io
  =/  mule-result
    %-  mule
    |.
    .^  *
        %gx
        (welp /(scot %p our.bowl)/[p.u.gen]/(scot %da now.bowl) path)
    ==
  ?>  ?=([? p=*] mule-result)
  ?.  -.mule-result
    (strand-fail %scry-failed (tang p.mule-result))
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+(crip "{<(en:json:html (json p.mule-result))>}")]
  ==
==
