/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'insert-file'
    '''
    Insert a file into the Clay filesystem.
    Will fail if the target desk doesn't have the given mark in /desk/mar/...
    '''
    %-  my
    :~  :-  'desk'
        :-  %string
        '''
        Target desk name (e.g. 'base' or 'my-app').
        '''
        :-  'filepath'
        :-  %string
        '''
        File path including mark at the end (e.g. '/foo/txt', '/app/my-app/hoon').
        '''
        :-  'content'
        :-  %string
        '''
        Content to write to the file.
        '''
    ==
    ~['desk' 'filepath' 'content']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  dek=(unit argument:tool:mcp)  (~(get by args) 'desk')
    ?~  dek
      ~|(%missing-desk !!)
    ?>  ?=([%string @t] u.dek)
    =/  fil=(unit argument:tool:mcp)  (~(get by args) 'filepath')
    ?~  fil
      ~|(%missing-filepath !!)
    ?>  ?=([%string @t] u.fil)
    =/  pax=path  (stab p.u.fil)
    =/  cot=(unit argument:tool:mcp)  (~(get by args) 'content')
    ?~  cot
      ~|(%missing-content !!)
    ?>  ?=([%string @t] u.cot)
    ;<  =bowl:rand  bind:m  get-bowl:io
    ;<  ~  bind:m
      %:  send-raw-card:io
          %pass   /insert-file
          %arvo   %c  %info
          [(@tas p.u.dek) %& [pax %ins (rear pax) !>(p.u.cot)]~]
      ==
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Inserted file {<pax>} into desk {<dek>}")]
    ==
==
