::  Uncached, diagnostic Hoon source builder.
::
::  Unlike Clay %a, this returns build errors to its caller.  Every source body
::  is guarded by a Clay %u existence scry and then fetched independently
::  through %x.  Only compiler/composition operations are virtualized.  This
::  first version supports /-, /+, and /= dependencies, which are the forms
::  used by this desk; unsupported forms return an error value.
::
|_  [our=@p =desk now=@da]
::  +build: build a /path/to/file/hoon and retain all compiler error tanks.
::
++  build
  |=  target=path
  ^-  (each vase tang)
  (build-file target ~)
::
::  +source-path: fully qualify a Clay source path.
::
++  source-path
  |=  local=path
  ^-  path
  (en-beam [our desk da+now] local)
::
::  +read-source: all actual file reads use the %x namespace.
::
++  read-source
  |=  local=path
  ^-  (unit @t)
  ?.  (exists local)  ~
  `[.^(@t %cx (source-path local))]
::
::  +exists: existence probes do not build or cache source.
::
++  exists
  |=  local=path
  ^-  ?
  .^(? %cu (source-path local))
::
::  +build-file: recursively build one source file with cycle detection.
::
++  build-file
  |=  [target=path active=(set path)]
  ^-  (each vase tang)
  ?:  (~(has in active) target)
    [%.n ~[leaf+"dependency cycle at {(spud target)}"]]
  =/  source=(unit @t)  (read-source target)
  ?~  source
    :-  %.n
    :~  leaf+"source file does not exist: {(spud target)}"
        leaf+"desk: {<desk>}, revision: {<now>}"
    ==
  =/  parsed=(each pile:clay tang)  (parse-pile target u.source)
  ?:  ?=(%| -.parsed)
    [%.n [leaf+"while parsing {(spud target)}" p.parsed]]
  =/  next=(set path)  (~(put in active) target)
  =/  subject=(each vase tang)  (run-prelude p.parsed next)
  ?:  ?=(%| -.subject)
    [%.n [leaf+"while building dependencies of {(spud target)}" p.subject]]
  =/  compiled  (mule |.((slub p.subject hoon.p.parsed)))
  ?-  -.compiled
    %|  [%.n [leaf+"while compiling {(spud target)}" p.compiled]]
    %&  compiled
  ==
::
::  +run-prelude: construct the compilation subject in Ford's order.
::
++  run-prelude
  |=  [parsed=pile:clay active=(set path)]
  ^-  (each vase tang)
  =/  subject=vase  !>(..zuse)
  =/  sur-result=(each vase tang)
    (run-tauts subject %sur sur.parsed active)
  ?:  ?=(%| -.sur-result)  sur-result
  =/  lib-result=(each vase tang)
    (run-tauts p.sur-result %lib lib.parsed active)
  ?:  ?=(%| -.lib-result)  lib-result
  =/  raw-result=(each vase tang)
    (run-raw p.lib-result raw.parsed active)
  ?:  ?=(%| -.raw-result)  raw-result
  ?:  ?|  ?=(^ raz.parsed)
          ?=(^ maz.parsed)
          ?=(^ caz.parsed)
          ?=(^ bar.parsed)
      ==
    [%.n ~[leaf+"builder: /~, /%, /$, and /* are not implemented"]]
  raw-result
::
::  +run-tauts: build /sur and /lib imports and compose their subjects.
::
++  run-tauts
  |=  $:  subject=vase
          kind=?(%lib %sur)
          imports=(list taut:clay)
          active=(set path)
      ==
  ^-  (each vase tang)
  ?~  imports  [%.y subject]
  =/  dependency=(unit path)  (fit-path kind pax.i.imports)
  ?~  dependency
    [%.n ~[leaf+"no files match /{(trip kind)}/{(trip pax.i.imports)}/hoon"]]
  =/  built=(each vase tang)  (build-file u.dependency active)
  ?:  ?=(%| -.built)  built
  =/  import=vase  p.built
  =?  p.import  ?=(^ face.i.imports)
    [%face u.face.i.imports p.import]
  =/  composed=vase  (slop import subject)
  $(subject composed, imports t.imports)
::
::  +run-raw: build direct /= path dependencies.
::
++  run-raw
  |=  $:  subject=vase
          imports=(list [face=term =path])
          active=(set path)
      ==
  ^-  (each vase tang)
  ?~  imports  [%.y subject]
  =/  dependency=path  (snoc path.i.imports %hoon)
  =/  built=(each vase tang)  (build-file dependency active)
  ?:  ?=(%| -.built)  built
  =/  import=vase  p.built
  =.  p.import  [%face face.i.imports p.import]
  =/  composed=vase  (slop import subject)
  $(subject composed, imports t.imports)
::
::  +fit-path: reproduce Clay's hyphen-to-path dependency search.
::
++  fit-path
  |=  [prefix=@tas name=@tas]
  ^-  (unit path)
  =/  candidates=(list path)  (segments name)
  |-
  ?~  candidates  ~
  =/  candidate=path  prefix^(snoc i.candidates %hoon)
  ?:  (exists candidate)  `candidate
  $(candidates t.candidates)
::
++  segments
  |=  suffix=@tas
  ^-  (list path)
  =/  parser
    (most hep (cook crip ;~(plug ;~(pose low nud) (star ;~(pose low nud)))))
  =/  torn=(list @tas)  (fall (rush suffix parser) ~[suffix])
  %-  flop
  |-  ^-  (list (list @tas))
  ?~  torn  ~
  ?:  ?=([@ ~] torn)
    ~[torn]
  %-  zing
  %+  turn  $(torn t.torn)
  |=  s=(list @tas)
  ^-  (list (list @tas))
  ?~  s  ~
  ~[[i.torn s] [(crip "{(trip i.torn)}-{(trip i.s)}") t.s]]
::
::  +parse-pile: Clay's prelude parser, copied without Ford/cache state.
::
++  parse-pile
  |=  [target=path source=@t]
  ^-  (each pile:clay tang)
  =/  [=hair result=(unit [parsed=pile:clay =nail])]
    %-  road  |.
    =>  [pile-rule=pile-rule target=target source=source trip=trip]
    ((pile-rule target) [1 1] (trip source))
  ?^  result  [%.y parsed.u.result]
  =/  line=@ud  p.hair
  =/  column=@ud  q.hair
  :-  %.n
  :~  leaf+"syntax error at [{<line>} {<column>}] in {<target>}"
    =/  lines=wain  (to-wain:format source)
    ?:  (gth line (lent lines))
      '<<end of file>>'
    (snag (dec line) lines)
    leaf+(runt [(dec column) '-'] "^")
  ==
::
++  pile-rule
  =>  ..lull
  =,  clay
  |=  pax=path
  %-  full
  %+  ifix
    :_  gay
    ::  parse optional /? and ignore
    ::
    ;~(plug gay (punt ;~(plug fas wut gap dem gap)))
  |^
  ;~  plug
    %+  cook  (bake zing (list (list taut)))
    %+  rune  hep
    (most ;~(plug com gaw) taut-rule)
  ::
    %+  cook  (bake zing (list (list taut)))
    %+  rune  lus
    (most ;~(plug com gaw) taut-rule)
  ::
    %+  rune  tis
    ;~(plug sym ;~(pfix gap stap))
  ::
    %+  rune  sig
    ;~((glue gap) sym wyde:vast stap)
  ::
    %+  rune  cen
    ;~(plug sym ;~(pfix gap ;~(pfix cen sym)))
  ::
    %+  rune  buc
    ;~  (glue gap)
      sym
      ;~(pfix cen sym)
      ;~(pfix cen sym)
    ==
  ::
    %+  rune  tar
    ;~  (glue gap)
      sym
      ;~(pfix cen sym)
      ;~(pfix stap)
    ==
  ::
    %+  stag  %tssg
    (most gap tall:(vang & pax))
  ==
  ::
  ++  pant
    |*  fel=^rule
    ;~(pose fel (easy ~))
  ::
  ++  mast
    |*  [bus=^rule fel=^rule]
    ;~(sfix (more bus fel) bus)
  ::
  ++  rune
    |*  [bus=^rule fel=^rule]
    %-  pant
    %+  mast  gap
    ;~(pfix fas bus gap fel)
  ::
  ++  taut-rule
    %+  cook  |=(taut +<)
    ;~  pose
      (stag ~ ;~(pfix tar sym))
      ;~(plug (stag ~ sym) ;~(pfix tis sym))
      (cook |=(a=term [`a a]) sym)
    ==
  --
--
