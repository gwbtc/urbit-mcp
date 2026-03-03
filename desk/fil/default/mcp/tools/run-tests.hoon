/-  mcp, spider
/+  io=strandio, libstrand=strand
=,  strand-fail=strand-fail:libstrand
^-  tool:mcp
:*  'run-tests'
    '''
    Run unit tests and/or integration tests, given a desk and a path prefix.
    '''
    %-  my
    :~  ['desk' [%string 'Desk name to run tests on (e.g. "base" or "mcp")']]
        ['path' [%string 'Path prefix for tests to run (e.g. "/tests" or "/tests/lib")']]
    ==
    ~['desk' 'path']
    ^-  thread-builder:tool:mcp
    =>
    |%
    ::  types adapted from /ted/test.hoon
    +$  test       [=path func=test-func]
    +$  test-arm   [name=term func=test-func]
    +$  test-func  (trap tang)
    ::
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
    ++  run-test
      |=  [pax=path test=test-func]
      ^-  [ok=? =tang text=@t]
      =+  name=(spud pax)
      =+  run=(mule test)
      ?-  -.run
        %|
        :*  ok=|
            tang=(welp p.run ~[leaf+"CRASHED {name}"])
            text=(crip "CRASHED {name}")
        ==
        %&
        ?:  =(~ p.run)
          [ok=& tang=~[leaf+"OK      {name}"] text=(crip "OK      {name}")]
        :*  ok=|
            tang=(flop `tang`[leaf+"FAILED  {name}" p.run])
            text=(crip "FAILED  {name}")
        ==
      ==
    ::
    ++  get-test-arms
      |=  [typ=type cor=*]
      ^-  (list test-arm)
      =/  arms=(list @tas)  (sloe typ)
      %+  turn  (skim arms has-test-prefix)
      |=  name=term
      ^-  test-arm
      =/  fire-arm=nock
        ~|  [%failed-to-compile-test-arm name]
        q:(~(mint ut typ) p:!>(*tang) [%limb name])
      [name |.(;;(tang ~>(%bout.[1 name] .*(cor fire-arm))))]
    ::
    ++  has-test-prefix
      |=  a=term  ^-  ?
      =((end [3 5] a) 'test-')
    ::
    ++  resolve-test-paths
      |=  paths-to-tests=(map path (list test-arm))
      ^-  (list test)
      %-  sort  :_  |=([a=test b=test] !(aor path.a path.b))
      ^-  (list test)
      %-  zing
      %+  turn  ~(tap by paths-to-tests)
      |=  [=path test-arms=(list test-arm)]
      ^-  (list test)
      %+  turn  test-arms
      |=  =test-arm
      ^-  test
      [(weld path /[name.test-arm]) func.test-arm]
    ::
    ++  find-test-files
      =|  fiz=(set [=beam test=(unit term)])
      =/  m  (strand:spider ,_fiz)
      |=  bez=(list beam)
      ^-  form:m
      =*  loop  $
      ?~  bez
        (pure:m fiz)
      ;<  hav=?  bind:m  (check-for-file:io -.i.bez (snoc s.i.bez %hoon))
      ?:  hav
        loop(bez t.bez, fiz (~(put in fiz) [i.bez(s (snoc s.i.bez %hoon)) ~]))
      ;<  fez=(list path)  bind:m  (list-tree:io i.bez)
      ?.  =(~ fez)
        =/  foz
          %+  murn  fez
          |=  p=path
          ?.  =(%hoon (rear p))  ~
          (some [[-.i.bez p] ~])
        loop(bez t.bez, fiz (~(gas in fiz) foz))
      ::  check if this could be a specific test arm name
      ::  try to extract test name and check for parent .hoon file
      =/  tex=term
        ~|  bad-test-beam+i.bez
        =-(?>(((sane %tas) -) -) (rear s.i.bez))
      =/  xup=path  (snip s.i.bez)
      ;<  hov=?  bind:m  (check-for-file:io i.bez(s (snoc xup %hoon)))
      ?.  hov
        loop(bez t.bez)  ::  no file found, skip this beam
      loop(bez t.bez, fiz (~(put in fiz) [[-.i.bez (snoc xup %hoon)] `tex]))
    --
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    ;<  =bowl:rand  bind:m  get-bowl:io
    =/  desk-arg=(unit argument:tool:mcp)  (~(get by args) 'desk')
    =/  path-arg=(unit argument:tool:mcp)  (~(get by args) 'path')
    ?~  desk-arg
      (strand-fail %missing-desk ~)
    ?>  ?=([%string @t] u.desk-arg)
    ?~  path-arg
      (strand-fail %missing-path ~)
    ?>  ?=([%string @t] u.path-arg)
    =/  desk=@tas  (@tas p.u.desk-arg)
    =/  test-path=path  (stab p.u.path-arg)
    ::  construct beam for the test path
    =/  bez=(list beam)
      :~  [[our.bowl desk da+now.bowl] test-path]
      ==
    ;<  fiz=(set [=beam test=(unit term)])  bind:m  (find-test-files bez)
    =>  .(fiz (sort ~(tap in fiz) aor))
    =|  test-arms=(map path (list test-arm))
    =|  build-failures=(list @t)
    |-  ^-  form:m
    =*  gather-tests  $
    ?^  fiz
      ;<  cor=(unit vase)  bind:m  (build-file:io beam.i.fiz)
      ?~  cor
        ::  build failed
        =/  fail-text=@t  (crip "FAILED  {(spud s.beam.i.fiz)} (build)")
        gather-tests(fiz t.fiz, build-failures [fail-text build-failures])
      =/  arms=(list test-arm)  (get-test-arms u.cor)
      ::  filter arms if specific test prefix specified
      =?  arms  ?=(^ test.i.fiz)
        %+  skim  arms
        |=  test-arm
        =((end [3 (met 3 u.test.i.fiz)] name) u.test.i.fiz)
      =.  test-arms  (~(put by test-arms) (snip s.beam.i.fiz) arms)
      gather-tests(fiz t.fiz)
    ::  run all tests and collect results
    =/  tests=(list test)  (resolve-test-paths test-arms)
    =|  test-results=(list @t)
    |-  ^-  form:m
    =*  run-tests-loop  $
    ?~  tests
      ::  format final output
      =/  all-results=(list @t)
        (weld (flop build-failures) (flop test-results))
      =/  final-output=@t
        ?~  all-results
          'No tests found'
        (of-wain:format all-results)
      %-  pure:m
      !>  ^-  json
      %-  pairs:enjs:format
      :~  ['type' s+'text']
          ['text' s+final-output]
      ==
    =/  [test-result-ok=? test-tang=tang result-text=@t]
      (run-test path.i.tests func.i.tests)
    ::  if test failed, include error details
    =/  full-result=@t
      ?:  test-result-ok
        result-text
      =/  error-lines=wain  (print-tang-to-wain test-tang)
      =/  formatted-errors=@t
        ?~  error-lines
          result-text
        (of-wain:format (weld [result-text ~] error-lines))
      formatted-errors
    run-tests-loop(tests t.tests, test-results [full-result test-results])
==
