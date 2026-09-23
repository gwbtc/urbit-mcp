/-  mcp, spider
/+  io=strandio, libstrand=strand, mm=mcp-mime
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
::
^-  tool:mcp
:*  'mcp/scry-agent'
  '''
  Run a %gx scry (read) to retrieve data from a Gall agent.
  A path ending in /json returns structured JSON. Any other mark is
  converted to %mime with the marks in the agent's desk, which must
  have /mar/<mark>/hoon with a +mime:grow arm.
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
      The scry path, ending in a mark (e.g. "/tools/json").
      '''
  ==
  ~['agent' 'path']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  gen=(unit argument:tool:mcp)  (~(get by args) 'agent')
  ?~  gen  (pure:m !>([%error %missing-agent ~]))
  =/  pax=(unit argument:tool:mcp)  (~(get by args) 'path')
  ?~  pax  (pure:m !>([%error %missing-path ~]))
  ?>  ?=([%string @t] u.gen)
  ?>  ?=([%string @t] u.pax)
  ::  slap path to handle interpolation, +scot etc.
  =/  =path  !<(path (slap !>(.) (ream p.u.pax)))
  ?~  path
    %-  pure:m
    !>  ^-  response:tool:mcp
    [%error %scry-path-must-end-in-mark `(frond:enjs:format %path s+p.u.pax)]
  ;<  =bowl:spider  bind:m  get-bowl:io
  =/  prefix=^path
    /(scot %p our.bowl)/[p.u.gen]/(scot %da now.bowl)
  =/  mule-result  (mule |.(.^(* %gx (welp prefix path))))
  ?:  ?=(%| -.mule-result)
    %-  pure:m
    !>  ^-  response:tool:mcp
    :-  %error
    :-  %scry-failed
    %-  some
    %-  frond:enjs:format
    :-  %stack-trace
    s+(of-wain:format (print-tang-to-wain p.mule-result))
  ?:  =(%json (rear path))
    %-  pure:m
    !>  ^-  response:tool:mcp
    :-  %result
    :-  %structured
    %-  frond:enjs:format
    :-  %result
    (json p.mule-result)
  ::  convert with the marks in the agent's desk
  ;<  mime-result=(each mime tang)  bind:m
    %+  page-to-mime:mm
      [our.bowl .^(desk %gd (snoc prefix %$)) da+now.bowl]
    [(slav %tas (rear path)) p.mule-result]
  ?:  ?=(%| -.mime-result)
    %-  pure:m
    !>  ^-  response:tool:mcp
    :+  %error
      (of-wain:format (print-tang-to-wain p.mime-result))
    `(frond:enjs:format %mark s+(rear path))
  =/  =mime  p.mime-result
  =/  type=@t  (mime-type:mm p.mime)
  =/  uri=@t  (rap 3 ~['scry://gx/' p.u.gen (spat path)])
  %-  pure:m
  !>  ^-  response:tool:mcp
  :+  %result  %unstructured
  :_  ~
  ?:  ?=([%image *] p.mime)
    [%image (en:base64:mimes:html q.mime) type ~]
  ?:  ?=([%audio *] p.mime)
    [%audio (en:base64:mimes:html q.mime) type]
  ?:  (text-mime:mm p.mime)
    [%resource uri type q.q.mime ~]
  [%resource-blob uri type (en:base64:mimes:html q.mime) ~]
==
