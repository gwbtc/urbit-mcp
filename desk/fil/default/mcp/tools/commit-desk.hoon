/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'commit-desk'
    '''
    Commit code changes to a desk.
    '''
    (my ['desk' [%string (crip "desk name (e.g. 'base' to commit the %base desk)")]]~)
    ~['desk']
    ^-  thread-builder:tool:mcp
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
    ::
    ::  rough, heuristic, opinionated
    ::  filter on userspace errors
    ++  prune-err
      |=  =tang
      ^-  (list tank)
      %+  murn
        tang
      |=  tak=tank
      ^-  (unit tank)
      ?+  tak
        ::  just a cord
        `tak
      ::
          [%leaf *]  ?~(p.tak ~ `[%leaf p.tak])
      ::
          [%palm *]  ?~(q.tak ~ `[%palm p.tak (prune-err q.tak)])
      ::
          [%rose *]
        ?~  q.tak
          ~
        ?:  ?|  =(i.q.tak [%leaf "sys"])
                =(p.tak [":" "" ""])
            ==
          ~
        `[%rose p.tak (prune-err q.tak)]
      ==
    --
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  dek=(unit argument:tool:mcp)  (~(get by args) 'desk')
    ?~  dek
      ~|(%missing-desk !!)
    ?>  ?=([%string *] u.dek)
    ;<  ~  bind:m
      (send-raw-card:io [%pass /dill-logs %arvo %d %logs `~])
    ;<  ~  bind:m
      (poke-our:io %hood %kiln-commit !>([(@tas p.u.dek) %.n]))
    ;<  [wire =sign-arvo]  bind:m
      ((set-timeout:io ,[wire sign-arvo]) ~s2 take-sign-arvo:io)
    ?>  ?=([%dill %logs *] sign-arvo)
    ;<  ~  bind:m
      (send-raw-card:io [%pass /dill-logs %arvo %d %logs ~])
    =/  [%dill %logs =told:dill]  sign-arvo
    ?-  told
      [%crud *]
      %-  pure:m
      !>  ^-  json
      %-  pairs:enjs:format
      :~  ['type' s+'text']
          :-  'text'
          :-  %s
          %-  crip
          "{<[%error p.told (print-tang-to-wain (prune-err q.told))]>}"
      ==
    ::
      [%talk *]
      ~&  >>  %talk
      ~&  >>  p.told
      %-  pure:m
      !>  ^-  json
      %-  pairs:enjs:format
      :~  ['type' s+'text']
          ['text' s+(crip "{<[%talk (print-tang-to-wain p.told)]>}")]
      ==
    ::
      [%text *]
      ::  XX stub, would be better to return list of changed files
      ::     need to get any more %text gifts that come in from Dill
      %-  pure:m
      !>  ^-  json
      %-  pairs:enjs:format
      :~  ['type' s+'text']
          ['text' s+'Commit successful!']
      ==
    ==
==
