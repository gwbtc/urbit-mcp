/-  mcp, spider
/+  io=strandio, ju=json-utils
^-  tool:mcp
:*  'commit-desk'
    'Commit code changes to a desk. If this errors with a timeout, there are no changes to commit.'
    (my ['desk' [%string (crip "desk name (e.g. 'base' to commit the %base desk)")]]~)
    ['desk']~
    ^-  thread-builder:mcp
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
    |=  args=(map @t json)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  args-json=json  [%o args]
    =/  desk-name=(unit @t)
      (fall (mole |.((~(deg jo:ju args-json) /desk so:dejs:format))) ~)
    ?~  desk-name  ~|(%missing-desk !!)
    =/  desk=@tas  (@tas u.desk-name)
    ;<  ~  bind:m
      (send-raw-card:io [%pass /dill-logs %arvo %d %logs `~])
    ;<  ~  bind:m
      (poke-our:io %hood %kiln-commit !>([desk %.n]))
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
          ['text' s+(crip "{<[%error p.told (print-tang-to-wain q.told)]>}")]
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
