|%
++  parse
  |=  uri=@t
  ^-  (unit spar:ames)
  =/  parts=(list @t)
    %+  turn
      (split "/" (slag (lent "fine://") (trip uri)))
    crip
  ?~  parts
    ~
  =/  target=(unit @p)  (slaw %p i.parts)
  ?~  target
    ~
  =/  fine-path=path  (to-path t.parts)
  =/  remote-path=(unit path)
    ?+  fine-path  ~
    ::  fine://~ship/c/x/revision/desk/path
        [%c %x @t @t [@t *]]
      =/  revision=@t  i.t.t.fine-path
      =/  desk=@t  i.t.t.t.fine-path
      =/  tail=path  t.t.t.t.fine-path
      =/  case-knot=(unit @ta)  (parse-case revision)
      ?~  case-knot
        ~
      `(welp /c/x/[u.case-knot]/[desk] tail)
    ::  fine://~ship/g/x/revision/agent//1/path
        [%g %x @t @t %$ %'1' [@t *]]
      =/  revision=@t  i.t.t.fine-path
      =/  agent=@t  i.t.t.t.fine-path
      =/  spur=path  t.t.t.t.t.t.fine-path
      =/  case-knot=(unit @ta)  (parse-case revision)
      ?~  case-knot
        ~
      `(welp /g/x/[u.case-knot]/[agent]/''/'1' spur)
    ==
  ?~  remote-path
    ~
  `[u.target u.remote-path]
::
++  parse-case
  |=  case-text=@t
  ^-  (unit @ta)
  =/  parsed  (rust (trip case-text) nuck:so)
  ?~  parsed
    ~
  ?.  ?=([%$ *] u.parsed)
    ~
  =/  =dime  p.u.parsed
  ?+  -.dime  `(scot %tas (@tas +.dime))
    %da  `(scot %da (@da +.dime))
    %ud  `(scot %ud (@ud +.dime))
    %uv  `(scot %uv (@uv +.dime))
  ==
::
++  to-path
  |=  parts=(list @t)
  ^-  path
  %-  stab
  %-  crip
  %-  tape
  :-('/' (join '/' parts))
::
++  split
  |=  [sep=tape =tape]
  ^-  (list ^tape)
  =|  res=(list ^tape)
  |-
  ?~  tape
    (flop res)
  =/  off  (find sep tape)
  ?~  off
    (flop [`^tape`tape `(list ^tape)`res])
  %=  $
    res   [(scag `@ud`(need off) `^tape`tape) res]
    tape  (slag +(`@ud`(need off)) `^tape`tape)
  ==
--
