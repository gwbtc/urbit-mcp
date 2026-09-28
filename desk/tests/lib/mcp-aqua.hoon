/+  *test, aq=mcp-aqua
|%
++  sample-run
  ^-  run:aq
  [%test %test-tid %base %ph-add %running ~2026.9.16 ~2026.9.16 0 0 0 ~ ~ supported-effects:aq 0 ~]
++  sample-state
  |=  r=run:aq
  ^-  state:aq
  [(~(put by *(map @ta run:aq)) %test r) ~]
++  field
  |=  [j=json key=@t]
  ^-  json
  ?>  ?=(%o -.j)
  (~(got by p.j) key)
++  test-render-and-partials
  =/  r=run:aq  sample-run
  =.  r  (blits:aq r ~2026.9.16..00.00.01 ~bud ~[[%mor ~[[%put (tuba "hello")] [%nel ~]]]])
  =.  r  (blits:aq r ~2026.9.16..00.00.02 ~dev ~[[%put (tuba "next")]])
  =.  r  (blits:aq r ~2026.9.16..00.00.03 ~dev ~[[%nel ~]])
  =/  first=record:aq  (~(got by records.r) 0)
  =/  second=record:aq  (~(got by records.r) 1)
  %+  weld
    (expect-eq !>(['hello' ~bud 1.000]) !>([text.first ship.first elapsed.first]))
  (expect-eq !>(['next' ~dev 3.000]) !>([text.second ship.second elapsed.second]))
++  test-styled-text-and-truncation
  =/  long=tape  (reap 1.000 'x')
  =/  line=line:aq  (styled-text:aq ~[[*stye (tuba "red")] [*stye (tuba " blue")]])
  =/  r=run:aq  (blits:aq sample-run ~2026.9.16 ~bud ~[[%put (tuba long)] [%nel ~]])
  =/  rec=record:aq  (~(got by records.r) 0)
  %+  weld
    (expect-eq !>("red blue") !>(text.line))
  (expect-eq !>([512 & &]) !>([(met 3 text.rec) truncated.rec (lte (record-bytes:aq rec) max-record-bytes:aq)]))
++  test-filter-and-prompts
  =/  r=run:aq  (blits:aq sample-run ~2026.9.16 ~bud ~[[%put (tuba "~bud:dojo> ")]])
  =.  r  (append:aq r ~2026.9.16 ~dev %restore %lifecycle "restore" |)
  =.  r  (append:aq r ~2026.9.16 ~bud %blit %output "done" |)
  =/  page=json  (read-json:aq (sample-state r) [%test 0 ~[~bud] ~[%blit] | 8.192])
  =/  records=json  (field page 'records')
  ?>  ?=(%a -.records)
  %+  weld
    (expect-eq !>(n+'3') !>((field page 'nextCursor')))
  (expect-eq !>(1) !>((lent p.records)))
++  test-unicode-and-json-numbers
  =/  chars=(list @c)  (reap 512 `@c`0x1.f680)
  =/  r=run:aq  (blits:aq sample-run ~2026.9.16..00.00.03 ~bud ~[[%put chars] [%nel ~]])
  =/  rec=record:aq  (~(got by records.r) 0)
  =/  jon=json  (record-json:aq rec)
  %+  weld
    (expect-eq !>([(crip (tufa chars)) |]) !>([text.rec truncated.rec]))
  (expect-eq !>(n+'3000') !>((field jon 'elapsedMs')))
++  test-retain-evicts-oldest-run
  =/  r=run:aq  sample-run
  =/  runs=(map @ta run:aq)
    (my ~[[%a r(started ~2026.9.12, status %completed)] [%b r(started ~2026.9.13, status %completed)] [%c r(started ~2026.9.14, status %completed)] [%d r(started ~2026.9.15, status %completed)]])
  =/  s=state:aq  (retain:aq [runs ~])
  (expect-eq !>([3 | &]) !>([(lent ~(tap by runs.s)) (~(has by runs.s) %a) (~(has by runs.s) %d)]))
++  test-eviction-and-page-budget
  =/  r=run:aq  sample-run
  =/  count=@ud  2.200
  =/  txt=tape  (reap 512 '"')
  =.  r
    |-
    ?:  =(0 count)  r
    $(count (dec count), r (append:aq r ~2026.9.16 ~bud %blit %output txt |))
  =/  page=json  (read-json:aq (sample-state r) [%test 0 ~ ~ | 8.192])
  =/  gap=json  (field page 'gap')
  %+  weld
    (expect-eq !>([& & &]) !>([(gth oldest.r 0) (lte bytes.r max-buffer-bytes:aq) (lte (sub next.r oldest.r) max-records:aq)]))
  %+  weld
    (expect-eq !>((numb:enjs:format oldest.r)) !>((field gap 'to')))
  (expect-eq !>(&) !>((lte (met 3 (en:json:html page)) 8.192)))
++  test-large-callback-is-not-retained
  =/  payload=*  (reap 10.000 [1 2 3])
  =/  r=run:aq  (observe:aq sample-run ~2026.9.16 [~bud [/ [%unto [%raw-fact %noun payload]]]])
  =/  rec=record:aq  (~(got by records.r) 0)
  (expect-eq !>('raw-fact mark=%noun; payload omitted') !>(text.rec))
++  test-unknown-effects-are-opaque
  =/  payload=*  (reap 10.000 [1 2 3])
  =/  r=run:aq  sample-run
  =.  r  r(effects [%fief %avow %future supported-effects:aq])
  =/  before=run:aq  r
  =.  r  (observe:aq r ~2026.9.16 [~bud [/ [%fief payload]]])
  =.  r  (observe:aq r ~2026.9.16 [~bud [/ [%avow payload]]])
  =.  r  (observe:aq r ~2026.9.16 [~bud [/ [%future payload]]])
  (expect-eq !>(before) !>(r))
++  test-filtered-malformed-payload-is-opaque
  =/  r=run:aq  sample-run
  =.  r  r(effects ~[%init])
  (expect-eq !>(r) !>((observe:aq r ~2026.9.16 [~bud [/ [%blit 42]]])))
++  test-malformed-effects-do-not-interrupt-capture
  =/  r=run:aq  (observe:aq sample-run ~2026.9.16 42)
  =.  r  (observe:aq r ~2026.9.16 [~bud [/ [%blit 42]]])
  =.  r  (observe:aq r ~2026.9.16 [~bud [/ [%request 42]]])
  =.  r  (observe:aq r ~2026.9.16 [~bud [/ [%blit ~[[%put (tuba "still running")] [%nel ~]]]]])
  =/  rec=record:aq  (~(got by records.r) 0)
  (expect-eq !>([3 1 'still running']) !>([omitted.r next.r text.rec]))
++  test-summary-only-decodes-required-fields
  =/  r=run:aq  (observe:aq sample-run ~2026.9.16 [~bud [/ [%request 123 42]]])
  =/  rec=record:aq  (~(got by records.r) 0)
  (expect-eq !>('HTTP request id=123; payload omitted') !>(text.rec))
++  test-combined-send-targets
  =/  direct=(unit target:aq)  (send-target:aq [%| ~dev])
  =/  galaxy=(unit target:aq)  (send-target:aq [%& ~nut])
  =/  upstream=(unit target:aq)  (send-target:aq [%| 0xdead.beef.cafe])
  ?>  ?&(?=(^ direct) ?=(^ galaxy) ?=(^ upstream))
  %+  weld
    (expect-eq !>([~dev %ship-id ~nut]) !>([ship.u.direct decoded-by.u.direct ship.u.galaxy]))
  (expect-eq !>([~londeg-tirlys-somlyd-poltus--pintyn-tarbyl-bicnux-marbud %upstream-comet]) !>(u.upstream))
++  test-groundwire-comet-targets
  =/  index=@ud  0
  =/  checks=tang  ~
  |-
  ?:  =(index 12)  checks
  =/  send=(unit target:aq)  (send-target:aq [%| (cat 5 0xdead.beef index)])
  =/  push=(unit target:aq)  (push-target:aq [%if 0xdead.beef index])
  ?>  &(?=(^ send) ?=(^ push))
  =/  expected=target:aq  [(snag index groundwire-comets:aq) %groundwire-comet]
  $(index +(index), checks (weld checks (weld (expect-eq !>(expected) !>(u.send)) (expect-eq !>(expected) !>(u.push)))))
++  test-network-summary-targets-and-bounds
  =/  r=run:aq  (observe:aq sample-run ~2026.9.16 [~bud [/ [%send [%| ~dev] 0]]])
  =/  rec=record:aq  (~(got by records.r) 0)
  =/  pushed=line:aq  (network-text:aq %push [(reap 100 ~dev) 0])
  %+  weld
    (expect-eq !>('network send; target=~dev decodedBy=%ship-id; packet omitted') !>(text.rec))
  (expect-eq !>([& &]) !>([truncated.pushed (lth (lent text.pushed) 512)]))
++  test-network-unknown-lanes
  =/  ipv6=(unit target:aq)  (push-target:aq [%is 0 0])
  =/  invalid=(unit target:aq)  (send-target:aq 42)
  =/  large=(unit target:aq)  (send-target:aq [%| (bex 1.000)])
  =/  atom=(unit target:aq)  (push-target:aq ~dev)
  ?>  ?=(^ atom)
  (expect-eq !>([~ ~ ~ ~dev]) !>([ipv6 invalid large ship.u.atom]))
++  test-finish-clears-partials
  =/  r=run:aq  (blits:aq sample-run ~2026.9.16 ~bud ~[[%put (tuba "last")]])
  =/  s=state:aq  [(~(put by *(map @ta run:aq)) %test r) `%test]
  =.  s  (complete:aq s %test ~2026.9.16 %cancelled ~)
  =/  done=run:aq  (~(got by runs.s) %test)
  (expect-eq !>([%cancelled ~ ~ 1]) !>([status.done active.s partials.done next.done]))
++  test-completion-drains-final-output
  =/  r=run:aq  (begin-finish:aq sample-run ~2026.9.16 ~)
  =.  r  (observe:aq r ~2026.9.16 [~bud [/ [%blit ~[[%put (tuba "hi ~dev successful")] [%nel ~]]]]])
  =/  s=state:aq  [(~(put by *(map @ta run:aq)) %test r) `%test]
  =/  final=(unit status:aq)  (drain-result:aq (drain-branch:aq %completed))
  ?>  ?=(^ final)
  =.  s  (complete:aq s %test ~2026.9.16 u.final ~)
  =/  done=run:aq  (~(got by runs.s) %test)
  =/  rec=record:aq  (~(got by records.done) 0)
  (expect-eq !>([%finishing | %completed ~ 'hi ~dev successful']) !>([status.r (terminal:aq status.r) status.done active.s text.rec]))
--
