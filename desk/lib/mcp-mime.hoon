::  convert marked data to %mime with the marks of the desk it came
::  from, and render %mime as mcp resource contents
/-  spider
/+  io=strandio
|%
::
::  +page-to-mime: validate .page and convert it with the marks in .beak.
::  clay builds the marks over %warp: a failed build inside .^ crashes
::  past +mule, while a %warp answers with an empty riot
++  page-to-mime
  |=  [=beak =page]
  =/  m  (strand:spider ,(each mime tang))
  ^-  form:m
  ?:  =(%mime p.page)
    (pure:m %& ;;(mime q.page))
  ?:  =(%json p.page)
    (pure:m %& /application/json (as-octs:mimes:html (en:json:html ;;(json q.page))))
  =/  fail=tang
    :_  ~
    :-  %leaf
    "can't convert %{(trip p.page)} to %mime; desk %{(trip q.beak)} needs /mar/{(trip p.page)}/hoon with +mime:grow"
  ;<  mar=riot:clay  bind:m  (warp:io p.beak q.beak ~ %sing %b r.beak /[p.page])
  ?~  mar
    (pure:m %| fail)
  ;<  cas=riot:clay  bind:m  (warp:io p.beak q.beak ~ %sing %c r.beak /[p.page]/mime)
  ?~  cas
    (pure:m %| fail)
  =/  =dais:clay  !<(dais:clay q.r.u.mar)
  =/  =tube:clay  !<(tube:clay q.r.u.cas)
  (pure:m (mule |.(!<(mime (tube (vale:dais q.page))))))
::
::  +text-mime: whether mcp should send .mite as text, not base64
++  text-mime
  |=  =mite
  ^-  ?
  ?|  ?=([%text *] mite)
      ?=([%application ?(%json %xml %javascript) ~] mite)
  ==
::
::  +mime-type: /text/plain to 'text/plain'
++  mime-type
  |=  =mite
  ^-  @t
  (rsh 3^1 (spat mite))
::
::  +contents: a resources/read contents entry for .mime at .uri
++  contents
  |=  [uri=@t =mime]
  ^-  json
  %-  pairs:enjs:format
  :~  ['uri' s+uri]
      ['mimeType' s+(mime-type p.mime)]
      ?:  (text-mime p.mime)
        ['text' s+q.q.mime]
      ['blob' s+(en:base64:mimes:html q.mime)]
  ==
--
