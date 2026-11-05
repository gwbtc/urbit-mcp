/-  mcp
|_  prompts=(list spec:prompt:mcp)
++  grad  %noun
++  grow
  |%
  ++  noun  prompts
  ++  json
  %-  pairs:enjs:format
  :~  :-  'prompts'
      :-  %a
      %+  turn
        prompts
      |=  prompt=spec:prompt:mcp
      %-  pairs:enjs:format
      :~  ['name' s+name.prompt]
          ['title' s+title.prompt]
          ['description' s+desc.prompt]
          :-  'arguments'
          :-  %a
          %+  turn
            arguments.prompt
          |=  arg=argument:prompt:mcp
          %-  pairs:enjs:format
          :~  ['name' s+name.arg]
              ['description' s+desc.arg]
              ['required' b+required.arg]
          ==
          :-  'icons'
          :-  %a
          %+  turn
            icons.prompt
          |=  =icon:prompt:mcp
          %-  pairs:enjs:format
          :~  ['src' s+src.icon]
              ['mimeType' s+mime-type.icon]
              :-  'sizes'
              :-  %a
              %+  turn
                sizes.icon
              |=  size=@t
              [%s size]
  ==  ==  ==
  --
++  grab
  |%
  ++  noun  ,(list spec:prompt:mcp)
  --
--
