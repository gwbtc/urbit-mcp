/-  mcp, spider
/+  io=strandio, pf=pretty-file
=,  strand-fail=strand-fail:strand:spider
^-  thread:spider
|=  arg=vase
=/  =(list path)  !<((list path) arg)
^-  shed:khan
=/  m  (strand:spider ,vase)
^-  form:m
;<  =bowl:rand  bind:m  get-bowl:io
|-
?~  list
  (pure:m !>(~))
;<  vux=(unit vase)  bind:m
  (build-file:io [our.bowl %mcp-server da+now.bowl] i.list)
?~  vux
  ~&  >>>  [%failed-to-build i.list]
  $(list t.list)
=/  =mark
  ?+  i.list  %noun
    [%fil %default %tools *]      %add-tool
    [%fil %default %prompts *]    %add-prompt
    [%fil %default %resources *]  %add-resource
  ==
~&  >  [%built i.list]
;<  ~  bind:m
  (poke-our:io %mcp-server mark u.vux)
$(list t.list)
