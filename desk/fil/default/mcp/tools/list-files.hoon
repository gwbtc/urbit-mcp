/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'list-files'
  '''
  List files in Clay under the given filepath.
  '''
  %-  my
  :~  :-  'desk'
      :-  %string
      '''
      The desk to list files from (e.g. 'base' or 'mcp').
      '''
  ::
      :-  'path'
      :-  %string
      '''
      The path to list files from (e.g. '/', /lib', '/tests/app').
      '''
  ==
  ~['desk' 'path']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  dek=(unit argument:tool:mcp)  (~(get by args) 'desk')
  =/  pax=(unit argument:tool:mcp)  (~(get by args) 'path')
  ?~  dek  ~|(%missing-desk !!)
  ?~  pax  ~|(%missing-path !!)
  ?>  ?=([%string *] u.dek)
  ?>  ?=([%string *] u.pax)
  ;<  =bowl:rand  bind:m  get-bowl:io
  =/  file-list=(list path)
    .^  (list path)
        %ct
        %+  welp
          /(scot %p our.bowl)/[(@tas p.u.dek)]/(scot %da now.bowl)
        (stab p.u.pax)
    ==
  =/  file-paths-as-cords=(list @t)
    %+  turn  file-list
    |=  =path
    (spat path)
  =/  formatted-output=@t
    ?~  file-paths-as-cords
      'No files found'
    (of-wain:format file-paths-as-cords)
  %-  pure:m
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['type' s+'text']
      ['text' s+formatted-output]
  ==
==
