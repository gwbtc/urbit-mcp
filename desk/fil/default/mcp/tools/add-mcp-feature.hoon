/-  mcp, spider
/+  io=strandio
=,  strand-fail=strand-fail:strand:spider
^-  tool:mcp
:*  'install-mcp-feature'
    '''
    Install a single MCP feature from a beam URI by
    building and adding it to the %mcp-server state.
    '''
    %-  my
    :~  :-  'beam'
        :-  %string
        '''
        The beam URI of the feature file to install
        (e.g. "beam://=/mcp/=/fil/default/tools/my-tool/hoon").
        '''
    ==
    ~['beam']
    ^-  thread-builder:tool:mcp
    =>
    |%
    ++  parse-beam-uri
      |=  [=cord =bowl:rand]
      ^-  (unit beam)
      ::  we don't need to validate the scheme here,
      ::  but a canonical beam:// URI parser should
      =/  stub-count
        %+  roll
          (trip cord)
        |=  [a=@tD b=@ud]
        ?:  =(a '=')
          +(b)
        b
      ?.  (gte 3 stub-count)
        ::  fail; a beam:// can have no more than three stubs
        ~
      ?:  =(0 stub-count)
        ::  skip dereferencing
        (de-beam (stab cord))
      |^  %.  %+  turn
                %+  split
                  "/"
                ::  normalise e.g. /===/ to /=/=/=/
                ::  works for any combination of values and =
                %^    replace
                    "=="
                  "=/="
                ::  remove beam:/, leaving / prefix on the tape
                (oust [0 7] (trip cord))
              crip
          ::  replace = path segments with default values
          |=  =(pole @t)
          ^-  (unit beam)
          ?+  pole  ~
              [her=@t dek=@t cas=@t und=*]
            %-  de-beam
            %-  stab
            %-  crip
            ;:  welp
                "/"
                ?.  =('=' her.pole)  (trip her.pole)  "{<our.bowl>}"
                "/"
                ::  XX don't hard-code %base and do *desk?
                ?.  =('=' dek.pole)  (trip dek.pole)  "base"
                "/"
                ?.  =('=' cas.pole)  (trip cas.pole)  "{<now.bowl>}"
                "/"
                (zing (turn (join '/' und.pole) trip))
            ==
          ==
      ::
      :: ~lagrev-nocfep/yard/~2026.2.5/lib/string/hoon
      ++  replace
        |=  [bit=tape bot=tape =tape]
        ^-  ^tape
        |-
        =/  off  (find bit tape)
        ?~  off  tape
        =/  clr  (oust [(need off) (lent bit)] tape)
        $(tape :(weld (scag (need off) clr) bot (slag (need off) clr)))
      ::
      ++  split
        |=  [sep=tape =tape]
        ^-  (list ^tape)
        =|  res=(list ^tape)
        |-
        ?~  tape  (flop res)
        =/  off  (find sep tape)
        ?~  off  (flop [`^tape`tape `(list ^tape)`res])
        %=  $
          res   [(scag `@ud`(need off) `^tape`tape) res]
          tape  (slag +(`@ud`(need off)) `^tape`tape)
        ==
      --
    --
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    ;<  =bowl:rand  bind:m  get-bowl:io
    =/  beam-uri=(unit argument:tool:mcp)
      (~(get by args) 'beam')
    ?~  beam-uri
      (strand-fail %missing-beam ~)
    ?>  ?=([%string @t] u.beam-uri)
    =/  bem=(unit beam)
      (parse-beam-uri p.u.beam-uri bowl)
    ?~  bem
      (strand-fail %invalid-beam-uri ~)
    ?.  =(p.u.bem our.bowl)
      (strand-fail %cant-install-foreign-tools ~)
    ;<  has=?  bind:m
      (check-for-file:io u.bem)
    ?.  has
      (strand-fail %no-file-at-this-path [%leaf " {<u.bem>}"]~)
    ;<  vux=(unit vase)  bind:m
      (build-file:io u.bem)
    ?~  vux
      (strand-fail %failed-to-build ~)
    =/  =mark
      ?+  s.u.bem  %noun
        [%fil %default %mcp %tools *]      %add-tool
        [%fil %default %mcp %prompts *]    %add-prompt
        [%fil %default %mcp %resources *]  %add-resource
      ==
    ;<  ~  bind:m
      (poke-our:io %mcp-server mark u.vux)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        :-  'text'
        :-  %s
        %-  crip
        """
        Installing feature from beam: {(trip p.u.beam-uri)}
        """
    ==
==
