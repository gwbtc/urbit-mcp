/-  mcp, spider
/+  io=strandio, pf=pretty-file
=,  strand-fail=strand-fail:strand:spider
^-  thread:spider
|=  arg=vase
=/  =(list beam)  !<((list beam) arg)
^-  shed:khan
=/  m  (strand:spider ,vase)
^-  form:m
;<  =bowl:rand  bind:m  get-bowl:io
|-
?~  list
  (pure:m !>(~))
=*  bem  i.list
?.  =(p.bem our.bowl)
  ~&  >>>  %cant-install-foreign-tools
  ~&  >>>  (en-beam bem)
  $(list t.list)
;<  vux=(unit vase)  bind:m
  (build-file:io bem)
?~  vux
  ~&  >>>  [%failed-to-build (en-beam bem)]
  $(list t.list)
=/  =mark
  ?+  s.bem  %noun
    [%fil %default %mcp %tools *]      %add-tool
    [%fil %default %mcp %prompts *]    %add-prompt
    [%fil %default %mcp %resources *]  %add-resource
  ==
;<  ~  bind:m
  (poke-our:io %mcp-server mark u.vux)
$(list t.list)
