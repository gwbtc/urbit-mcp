/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'build-file'
  '''
  Build a source file from a Clay desk and return success or failure.
  '''
  %-  my
  :~  ['desk' [%string 'The desk containing the file (e.g. "base" or "mcp")']]
      ['path' [%string 'The path to the file to build (e.g. "/lib/foo/hoon")']]
  ==
  ~['desk' 'path']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  desk-arg=(unit argument:tool:mcp)  (~(get by args) 'desk')
  =/  path-arg=(unit argument:tool:mcp)  (~(get by args) 'path')
  ?~  desk-arg
    (strand-fail %missing-desk ~)
  ?>  ?=([%string @t] u.desk-arg)
  ?~  path-arg
    (strand-fail %missing-path ~)
  ?>  ?=([%string @t] u.path-arg)
  =/  =desk  (@tas p.u.desk-arg)
  ::  slap path to handle interpolation, +scot etc.
  =/  =path  !<(path (slap !>(.) (ream p.u.path-arg)))
  ;<  =bowl:spider  bind:m  get-bowl:io
  ;<  vux=(unit vase)  bind:m
    (build-file:io [our.bowl desk da+now.bowl] path)
  ?~  vux
    (strand-fail %build-failed ~)
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+'Build succeeded!']
  ==
==
