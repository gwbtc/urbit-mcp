/-  mcp, spider
/+  io=strandio, libstrand=strand
=,  strand=strand:libstrand
^-  tool:mcp
:*  'mcp/commit-desk'
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
    ::
    ++  safe-set-timeout
      |*  computation-result=mold
      =/  m  (strand ,computation-result)
      |=  [time=@dr computation=form:m]
      ^-  form:m
      ;<  now=@da  bind:m  get-time:io
      =/  when  (add now time)
      =/  =card:agent:gall
        [%pass /timeout/(scot %da when) %arvo %b %wait when]
      ;<  ~  bind:m  (send-raw-card:io card)
      |=  tin=strand-input:strand
      =*  loop  $
      ?:  ?&  ?=([~ %sign [%timeout @ ~] %behn %wake *] in.tin)
              =((scot %da when) i.t.wire.u.in.tin)
          ==
        `[%done ~]
      =/  c-res  (computation tin)
      ?:  ?=(%cont -.next.c-res)
        c-res(self.next ..loop(computation self.next.c-res))
      ?:  ?=(%done -.next.c-res)
        =/  =card:agent:gall
          [%pass /timeout/(scot %da when) %arvo %b %rest when]
        c-res(cards [card cards.c-res])
      c-res
    --
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  dek=(unit argument:tool:mcp)  (~(get by args) 'desk')
    ?~  dek
      (pure:m !>([%error %missing-desk ~]))
    ?>  ?=([%string *] u.dek)
    ;<  bo1=bowl:rand  bind:m  get-bowl:io
    =/  old-files=(list spur)
      .^  (list spur)
          %ct
          /(scot %p our.bo1)/[p.u.dek]/(scot %da now.bo1)
      ==
    =/  old-hashes=(map spur @uvI)
      %-  my
      %+  turn
        old-files
      |=  =spur
      ^-  (pair ^spur @uvI)
      :-  spur
      .^  @uvI
          %cz
          %+  welp
            /(scot %p our.bo1)/[p.u.dek]/(scot %da now.bo1)
          spur
      ==
    ;<  ~  bind:m
      %-  send-raw-card:io
      :*  %pass  /desk-update
          %arvo  %c
          %warp  [our.bo1 p.u.dek ~ %next %x da+now.bo1 /]
      ==
    ;<  ~  bind:m
      (send-raw-card:io [%pass /dill-logs %arvo %d %logs `~])
    ;<  ~  bind:m
      (poke-our:io %hood %kiln-commit !>([(@tas p.u.dek) %.n]))
    ;<  maybe-dill-sign=(unit sign-arvo)  bind:m
      %+  (safe-set-timeout (unit sign-arvo))
        ~s10
      =/  m  (strand ,(unit sign-arvo))
      ^-  form:m
      |=  tin=strand-input:strand
      ?+    in.tin  `[%skip ~]
          ~
        `[%wait ~]
      ::
          [~ %sign *]
        ?.  =(/dill-logs wire.u.in.tin)
          `[%skip ~]
        `[%done `sign-arvo.u.in.tin]
      ==
    ?~  maybe-dill-sign
      (pure:m !>([%error %no-changes-to-commit ~]))
    ?>  ?=([%dill %logs *] u.maybe-dill-sign)
    ;<  ~  bind:m
      (send-raw-card:io [%pass /dill-logs %arvo %d %logs ~])
    =/  [%dill %logs =told:dill]  u.maybe-dill-sign
    ?-    told
        [%crud *]
      =/  error-lines=wain
        (print-tang-to-wain (prune-err q.told))
      %-  pure:m
      !>  ^-  response:tool:mcp
      :-  %error
      :-  (of-wain:format error-lines)
      %-  some
      %-  pairs:enjs:format
      :_  ~
      :-  'trace'
      :-  %a
      %+  turn
        error-lines
      |=  =cord
      s+cord
    ::
        [%talk *]
      %-  pure:m
      !>  ^-  response:tool:mcp
      :-  %result
      :-  %structured
      %-  pairs:enjs:format
      :_  ~
      :-  'output'
      :-  %a
      %+  turn
        (print-tang-to-wain p.told)
      |=  =cord
      s+cord
    ::
        [%text *]
      ;<  bo2=bowl:rand  bind:m  get-bowl:io
      ;<  =sign-arvo  bind:m
        =/  m  (strand ,sign-arvo)
        ^-  form:m
        |=  tin=strand-input:strand
        ?+    in.tin  `[%skip ~]
            ~
          `[%wait ~]
        ::
            [~ %sign *]
          ?.  =(/desk-update wire.u.in.tin)
            `[%skip ~]
          `[%done sign-arvo.u.in.tin]
        ==
      ?>  ?=([%clay %writ *] sign-arvo)
      =/  new-files=(list spur)
        .^  (list spur)
            %ct
            /(scot %p our.bo2)/[p.u.dek]/(scot %da now.bo2)
        ==
      =/  new-hashes=(map spur @uvI)
        %-  my
        %+  turn
          new-files
        |=  =spur
        ^-  (pair ^spur @uvI)
        :-  spur
        .^  @uvI
            %cz
            %+  welp
              /(scot %p our.bo2)/[p.u.dek]/(scot %da now.bo2)
            spur
        ==
      =/  modified=(list spur)
        %+  murn
          new-files
        |=  =spur
        ^-  (unit ^spur)
        ?:  ?=(~ (find ~[spur] old-files))
          ~
        ?:  =((~(got by old-hashes) spur) (~(got by new-hashes) spur))
          ~
        `spur
      =/  added=(list spur)
        %+  murn
          new-files
        |=  =spur
        ^-  (unit ^spur)
        ?:  ?=(~ (find ~[spur] old-files))
          `spur
        ~
      =/  deleted=(list spur)
        %+  murn
          old-files
        |=  =spur
        ^-  (unit ^spur)
        ?.  ?=(~ (find ~[spur] new-files))
          ~
        `spur
      %-  pure:m
      !>  ^-  response:tool:mcp
      :-  %result
      :-  %structured
      %-  pairs:enjs:format
      :~  ['added' [%a ?~(added ~ (turn added |=(=spur s+(spat spur))))]]
          ['deleted' [%a ?~(deleted ~ (turn deleted |=(=spur s+(spat spur))))]]
          ['modified' [%a ?~(modified ~ (turn modified |=(=spur s+(spat spur))))]]
      ==
    ==
==
