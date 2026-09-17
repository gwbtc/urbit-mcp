::  Bounded, pure rendering/storage for Aqua's structured /effect stream.
::  No raw effects, returned vases, terminal sessions, or slog subscriptions.
|%
+$  status  ?(%starting %running %cancelling %finishing %completed %failed %cancelled %interrupted)
::
+$  record
  $:  cursor=@ud
      ship=@p
      effect=@tas
      kind=@tas
      text=@t
      observed=@da
      elapsed=@ud
      truncated=?
  ==
::
+$  line  [text=tape truncated=?]
+$  target  [ship=@p decoded-by=@tas]
::
+$  run
  $:  id=@ta
      tid=@ta
      desk=@tas
      term=@tas
      status=status
      started=@da
      updated=@da
      oldest=@ud
      next=@ud
      bytes=@ud
      records=(map @ud record)
      partials=(map @p line)
      effects=(list @tas)
      omitted=@ud
      error=(unit @t)
  ==
::
+$  state  [runs=(map @ta run) active=(unit @ta)]
::
+$  action
  $%  [%start id=@ta desk=@tas term=@tas arg=vase effects=(list @tas)]
      [%cancel id=@ta]
      [%release id=@ta]
  ==
::
+$  query
  [id=@ta cursor=@ud ships=(list @p) effects=(list @tas) prompts=? max-bytes=@ud]
::
++  max-runs  4
++  max-records  2.048
++  max-buffer-bytes  1.048.576
++  max-record-bytes  4.096
++  max-response-bytes  32.768
++  default-effects  ~[%blit %init %sleep %restore %kill]
::
++  supported-effects
  ~[%blit %init %sleep %restore %kill %unto %thus %request %ergo %saxo %nail %turf %send %push %doze]
::
++  terminal
  |=  s=status
  ?=(?(%completed %failed %cancelled %interrupted) s)
::
++  begin-finish
  |=  [r=run now=@da error=(unit @t)]
  ^-  run
  r(status %finishing, updated now, error error)
::
++  drain-branch
  |=  s=status
  ^-  @tas
  ?+  s  !!
    %completed    %drain-completed
    %failed       %drain-failed
    %cancelled    %drain-cancelled
    %interrupted  %drain-interrupted
  ==
::
++  drain-result
  |=  branch=@tas
  ^-  (unit status)
  ?+  branch  ~
    %drain-completed    `%completed
    %drain-failed       `%failed
    %drain-cancelled    `%cancelled
    %drain-interrupted  `%interrupted
  ==
::
++  elapsed-ms
  |=  [started=@da now=@da]
  (div (mul (sub (max started now) started) 1.000) ~s1)
::
++  record-json
  |=  r=record
  %-  pairs:enjs:format
  :~  ['cursor' (numb:enjs:format cursor.r)]
      ['ship' s+(scot %p ship.r)]
      ['effect' s+effect.r]
      ['type' s+kind.r]
      ['text' s+text.r]
      ['observedAt' s+(scot %da observed.r)]
      ['elapsedMs' (numb:enjs:format elapsed.r)]
      ['truncated' b+truncated.r]
  ==
::
++  record-bytes
  |=  r=record
  (met 3 (en:json:html (record-json r)))
::
++  append
  |=  [r=run now=@da who=@p effect=@tas kind=@tas txt=tape cut=?]
  ^-  run
  =/  chars=(list @c)  (tuba txt)
  =/  clipped=tape  (tufa (scag 512 chars))
  =/  rec=record
    [next.r who effect kind (crip clipped) now (elapsed-ms started.r now) |(cut ?=(^ (slag 512 chars)))]
  ::  Bound JSON size too (escaping can expand text).
  =?  rec  (gth (record-bytes rec) max-record-bytes)
    rec(text (crip (tufa (scag 128 (tuba clipped)))), truncated &)
  =.  r
    r(next +(next.r), bytes (add bytes.r (record-bytes rec)), records (~(put by records.r) cursor.rec rec), updated now)
  |-
  ?:  &((lte bytes.r max-buffer-bytes) (lte (sub next.r oldest.r) max-records))
    r
  =/  old=record  (~(got by records.r) oldest.r)
  $(r r(oldest +(oldest.r), bytes (sub bytes.r (record-bytes old)), records (~(del by records.r) oldest.r)))
::  Bound both Unicode traversal and styled-segment traversal.
::
++  styled-text
  |=  chunks=stub
  ^-  line
  =|  out=(list @c)
  =/  budget=@ud  128
  |-
  ?~  chunks
    [(tufa out) |]
  ?:  |(=(0 budget) (gte (lent out) 512))  [(tufa out) &]
  =/  txt=(list @c)  (scag (sub 512 (lent out)) q.i.chunks)
  ?:  ?=(^ (slag (sub 512 (lent out)) q.i.chunks))
    [(tufa (weld out txt)) &]
  $(chunks t.chunks, out (weld out txt), budget (dec budget))
::  Frames replace the current line, as in aqua/dill. Newlines emit records.
::  Work-list and recursion are limited to 512 blits per incoming fact.
::
++  blits
  |=  [r=run now=@da who=@p bs=(list blit:dill)]
  ^-  run
  =/  old=line  (~(gut by partials.r) who *line)
  =/  cur=line  old
  =/  work=(list blit:dill)  (scag 512 bs)
  =/  budget=@ud  512
  =/  limited=?  ?=(^ (slag 512 bs))
  |^
  |-
  ?~  work
    (finish r cur limited)
  ?:  =(0 budget)  (finish r cur &)
  =/  b=blit:dill  i.work
  =/  rest=(list blit:dill)  t.work
  =.  budget  (dec budget)
  ?+    -.b  $(work rest)
      %clr  $(work rest, cur *line)
      %wyp  $(work rest, cur *line)
      %put  $(work rest, cur [(tufa (scag 512 p.b)) ?=(^ (slag 512 p.b))])
      %klr  $(work rest, cur (styled-text p.b))
      %mor  $(work (weld (scag budget p.b) rest), limited |(limited ?=(^ (slag budget p.b))))
      %nel
    =?  r  ?=(^ text.cur)
      (append r now who %blit %output text.cur |(limited truncated.cur))
    $(work rest, cur *line)
  ==
  ::
  ++  finish
    |=  [r=run cur=line limited=?]
    ^-  run
    =.  cur  cur(truncated |(truncated.cur limited))
    =?  r  limited  r(omitted +(omitted.r))
    ::  Keep at most 64 bounded per-ship partial lines. Never keep effects.
    ?:  &(!(~(has by partials.r) who) (gte (lent ~(tap by partials.r)) 64))
      r(omitted +(omitted.r))
    =?  r
      ?&  !=(cur old)
          ?=(^ text.cur)
          ?=(^ (find ":dojo>" text.cur))
      ==
      (append r now who %blit %prompt text.cur truncated.cur)
    r(partials (~(put by partials.r) who cur))
  --
::
++  observe
  |=  [r=run now=@da effect=*]
  ^-  run
  ::  Neither the unused wire nor the payload needs full effect validation.
  ?.  ?=([@ * [@ *]] effect)  r(omitted +(omitted.r))
  =/  envelope=[who=@p way=* card=[tag=@tas payload=*]]  effect
  =/  who=@p  who.envelope
  =/  tag=@tas  tag.card.envelope
  =/  payload=*  payload.card.envelope
  ?.  (~(has in (sy `(list @tas)`supported-effects)) tag)  r
  ?.  (~(has in (sy effects.r)) tag)  r
  ::  A malformed selected payload must not crash Gall's subscription.
  =/  result  (mule |.((observe-selected r now who tag payload)))
  ?-  -.result
    %|  r(omitted +(omitted.r))
    %&  p.result
  ==
::
++  observe-selected
  |=  [r=run now=@da who=@p tag=@tas payload=*]
  ^-  run
  ?:  =(%blit tag)
    (blits r now who ;;((list blit:dill) payload))
  =/  network=line
    ?:  ?=(?(%send %push) tag)  (network-text tag payload)
    [~ |]
  =/  txt=tape
    ?+    tag  (trip tag)
        %send  text.network
        %push  text.network
        %unto
      ?>  ?=([@ *] payload)
      ?:  =(%raw-fact -.payload)
        ?>  ?=([@ *] +.payload)
        =/  fact=[mark=@tas data=*]  +.payload
        "raw-fact mark=%{(trip (end [3 128] mark.fact))}; payload omitted"
      "{(trip (end [3 128] -.payload))}; payload omitted"
    ::
        %thus
      ?>  ?=([@ *] payload)
      "HTTP request/cancel id={(scow %ud (end [0 64] -.payload))}; payload omitted"
    ::
        %request
      ?>  ?=([@ *] payload)
      "HTTP request id={(scow %ud (end [0 64] -.payload))}; payload omitted"
    ::
        %ergo
      ?>  ?=([@ *] payload)
      "filesystem export desk=%{(trip (end [3 128] -.payload))}; paths/payload omitted"
    ==
  (append r now who tag ?:(?=(?(%init %sleep %restore %kill) tag) %lifecycle %effect) txt truncated.network)
::  Aqua synthetic transport addresses, not general IP-to-ship resolution.
::
++  groundwire-comets
  ^-  (list @p)
  :~  ~fasteg-dinhet-malrum-ransub--hocduc-digtev-radsut-marbud
      ~daldyl-nildem-dispec-tilryx--dondus-dirmet-tintyl-marbud
      ~dansyr-ponbec-tocfel-laddux--socnut-nisnyx-dinsut-marbud
      ~harrep-podpec-torsut-docnyx--mopsyx-fosdus-ladpen-marbud
      ~liblyn-togrut-tabwel-hodbet--dovbex-parryt-mirbyt-marbud
      ~hidreb-naptev-banben-bicrup--massup-dantus-fodwet-marbud
      ~molpyx-novtyc-wortyc-noswyd--taltyv-loplev-dabwen-mardev
      ~fosnys-noctyd-talfyl-borryl--davhus-disbyn-fotnec-mardev
      ~tonmep-tabrux-rinbep-firmur--silmex-saldef-pasfer-mardev
      ~holwyx-ramped-tognet-barsyn--navler-ronmeg-topbex-mardev
      ~hacmet-doslyr-narhut-tiptec--micbyl-motnev-worsyn-mardev
      ~ribmut-nopdul-minmet-pardeg--wisfex-rosfus-fogsyn-mardev
  ==
::
++  ship-target
  |=  s=@
  ^-  (unit target)
  ?:  (gth (met 0 s) 128)  ~
  `[`@p`s %ship-id]
::
++  address-target
  |=  address=@
  ^-  (unit target)
  ?:  =(address 0xdead.beef.cafe)
    `[~londeg-tirlys-somlyd-poltus--pintyn-tarbyl-bicnux-marbud %upstream-comet]
  ?:  &(=(0xdead.beef (end 5 address)) (lth (rsh 5 address) 12))
    `[(snag (rsh 5 address) groundwire-comets) %groundwire-comet]
  (ship-target address)
::
++  send-target
  |=  lane=*
  ^-  (unit target)
  ?.  ?=([? @] lane)  ~
  ?:  -.lane  (ship-target +.lane)
  (address-target +.lane)
::
++  push-target
  |=  lane=*
  ^-  (unit target)
  ?@  lane  (ship-target lane)
  ?.  ?=([%if @ @] lane)  ~
  =/  ipv4=[%if ip=@ port=@]  lane
  ::  Synthetic Mesa IPv4 lanes concatenate 32-bit IP and port fields.
  ?:  |((gth (met 0 ip.ipv4) 32) (gth (met 0 port.ipv4) 16))  ~
  (address-target (cat 5 ip.ipv4 port.ipv4))
::
++  target-text
  |=  decoded=(unit target)
  ^-  tape
  ?~  decoded
    "unresolved"
  "{(scow %p ship.u.decoded)} decodedBy=%{(trip decoded-by.u.decoded)}"
::
++  network-text
  |=  [tag=@tas payload=*]
  ^-  line
  ?>  ?=([* @] payload)
  ?:  =(%send tag)
    ["network send; target={(target-text (send-target -.payload))}; packet omitted" |]
  =/  lanes=*  -.payload
  =/  out=tape  "network push; lane targets=["
  =/  budget=@ud  4
  |-
  ?:  =(0 budget)
    ["{out}{?:(=(~ lanes) "" "; remaining lanes omitted")}]; packet omitted" !=(~ lanes)]
  ?@  lanes
    ?>  =(~ lanes)
    ["{out}]; packet omitted" |]
  =.  out
    "{out}{?:(=(4 budget) "" "; ")}{(target-text (push-target -.lanes))}"
  $(lanes +.lanes, budget (dec budget))
::
++  flush
  |=  [r=run now=@da]
  ^-  run
  =/  ps=(list (pair @p line))  ~(tap by partials.r)
  |-
  ?~  ps
    r(partials ~)
  =/  who=@p  p.i.ps
  =/  cur=line  q.i.ps
  =?  r
    &(?=(^ text.cur) ?=(~ (find ":dojo>" text.cur)))
    (append r now who %blit %output text.cur truncated.cur)
  $(ps t.ps)
::
++  retain
  |=  s=state
  ^-  state
  ?:  (lth (lent ~(tap by runs.s)) max-runs)  s
  =/  candidates=(list (pair @ta run))  ~(tap by runs.s)
  =/  victim=(pair @ta run)  (head candidates)
  |-  ^-  state
  ?~  candidates
    s(runs (~(del by runs.s) p.victim))
  =?  victim  (lth started.q.i.candidates started.q.victim)  i.candidates
  $(candidates t.candidates)
::  Discard partial terminal buffers at termination; do not retain result vases.
::
++  complete
  |=  [s=state id=@ta now=@da result=status error=(unit @t)]
  ^-  state
  =/  got=(unit run)  (~(get by runs.s) id)
  ?~  got
    s
  =/  r=run  (flush u.got now)
  =.  r  r(status result, updated now, error error)
  s(runs (~(put by runs.s) id r), active ?:(=(active.s `id) ~ active.s))
::
++  matches-ship
  |=  [ships=(list @p) who=@p]
  ^-  ?
  |-
  ?~  ships
    |
  ?:  =(who i.ships)  &
  $(ships t.ships)
::
++  matches-effect
  |=  [effects=(list @tas) effect=@tas]
  ^-  ?
  |-
  ?~  effects
    |
  ?:  =(effect i.effects)  &
  $(effects t.effects)
::  One bounded page. Cursor advances over filtered records, never past an
::  eligible record that does not fit. Budget covers serialized JSON + envelope.
::
++  read-json
  |=  [s=state q=query]
  ^-  json
  =/  got=(unit run)  (~(get by runs.s) id.q)
  ?~  got
    (pairs:enjs:format ~[['error' s+'unknown run ID']])
  =/  r=run  u.got
  =/  pos=@ud  (min next.r (max oldest.r cursor.q))
  =/  effective=@ud  (min max-response-bytes (max 8.192 max-bytes.q))
  =/  budget=@ud  (sub effective 2.048)
  =|  out=(list json)
  =/  scan=@ud  2.048
  |^
  |-
  ?:  |((gte pos next.r) =(0 scan))  (envelope pos out effective)
  =/  rec=record  (~(got by records.r) pos)
  =/  eligible=?
    ?&  |(=(~ ships.q) (matches-ship ships.q ship.rec))
        |(=(~ effects.q) (matches-effect effects.q effect.rec))
        |(prompts.q !=(%prompt kind.rec))
    ==
  ?.  eligible  $(pos +(pos), scan (dec scan))
  =/  jon=json  (record-json rec)
  =/  size=@ud  (add 1 (record-bytes rec))
  ?:  (gth size budget)  (envelope pos out effective)
  $(pos +(pos), scan (dec scan), out [jon out], budget (sub budget size))
  ++  envelope
    |=  [pos=@ud out=(list json) effective=@ud]
    ^-  json
    =/  fields=(list [@t json])
      :~  ['runId' s+id.r]
          ['status' s+status.r]
          ['startedAt' s+(scot %da started.r)]
          ['updatedAt' s+(scot %da updated.r)]
          ['records' a+(flop out)]
          ['nextCursor' (numb:enjs:format pos)]
          ['oldestCursor' (numb:enjs:format oldest.r)]
          ['hasMore' b+(lth pos next.r)]
          ['effectiveMaxBytes' (numb:enjs:format effective)]
          ['retainedBytes' (numb:enjs:format bytes.r)]
          ['omittedEffects' (numb:enjs:format omitted.r)]
          ['captureEffects' a+(turn effects.r |=(e=@tas s+e))]
      ==
    =/  extra=(list [@t json])
      ?:  (lth cursor.q oldest.r)
        ~[['gap' (pairs:enjs:format ~[['from' (numb:enjs:format cursor.q)] ['to' (numb:enjs:format oldest.r)]])]]
      ~
    =/  err=(list [@t json])
      ?~  error.r
        ~
      ~[['error' s+u.error.r]]
    (pairs:enjs:format (weld fields (weld extra err)))
  --
--
