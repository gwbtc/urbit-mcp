/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'mcp/insert-file'
    '''
    Insert a file into the Clay filesystem.
    Content is supplied as text and converted to the target mark through that
    mark's +grab:mime arm, exactly as if the file had been written into a
    mounted desk and committed. Structured marks (%bill, %kelvin, %docket-0,
    %json) therefore work as well as source marks (%hoon, %txt, %md).
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
      (pure:m !>([%error %missing-desk ~]))
    ?>  ?=([%string @t] u.dek)
    =/  fil=(unit argument:tool:mcp)  (~(get by args) 'filepath')
    ?~  fil
      (pure:m !>([%error %missing-filepath ~]))
    ?>  ?=([%string @t] u.fil)
    =/  pax=path  (stab p.u.fil)
    =/  cot=(unit argument:tool:mcp)  (~(get by args) 'content')
    ?~  cot
      (pure:m !>([%error %missing-context ~]))
    ?>  ?=([%string @t] u.cot)
    ;<  =bowl:rand  bind:m  get-bowl:io
    =/  des=desk  (@tas p.u.dek)
    ::  own: a beam we know exists, for enumerating desks
    ::  bek: the target desk's beam, for mark lookup and conversion
    ::
    =/  own=path  /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)
    =/  bek=path  /(scot %p our.bowl)/[des]/(scot %da now.bowl)
    ?.  ?=([@ @ *] pax)
      %-  pure:m
      !>  ^-  response:tool:mcp
      :+  %error
        'filepath needs at least two components, ending in the mark (e.g. /desk/bill)'
      ~
    ?.  (~(has in .^((set desk) %cd own)) des)
      %-  pure:m
      !>  ^-  response:tool:mcp
      [%error (crip "no such desk: %{(trip des)}") ~]
    =/  mar=mark  (rear pax)
    ?.  .^(? %cu (weld bek /mar/[mar]/hoon))
      %-  pure:m
      !>  ^-  response:tool:mcp
      [%error (crip "desk %{(trip des)} has no /mar/{(trip mar)}/hoon") ~]
    ::  convert text -> %mime -> target mark, the way a commit would
    ::
    =/  =tube:clay  .^(tube:clay %cc (weld bek /mime/[mar]))
    =/  vax=vase  (tube !>(`mime`[/text/plain (as-octs:mimes:html p.u.cot)]))
    ;<  ~  bind:m
      %:  send-raw-card:io
          %pass   /insert-file
          %arvo   %c  %info
          [des %& [pax %ins mar vax]~]
      ==
    %-  pure:m
    !>  ^-  response:tool:mcp
    :-  %result
    :-  %unstructured
    :~  [%text (crip "Inserted {(spud pax)} into desk %{(trip des)}")]
    ==
==
