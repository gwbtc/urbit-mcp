/-  sole
/+  *test, sol=sole, dj=mcp-dojo
|%
++  test-valid-name
  ;:  weld
    (expect-eq !>(&) !>((valid-name:dj 'my-session.1')))
    (expect-eq !>(|) !>((valid-name:dj '')))
    (expect-eq !>(|) !>((valid-name:dj 'Has Space')))
    (expect-eq !>(|) !>((valid-name:dj 'a/b')))
    (expect-eq !>(|) !>((valid-name:dj (crip (reap 65 'a')))))
  ==
::
++  test-settled
  ;:  weld
    (expect-eq !>(&) !>((settled:dj [%pro & %$ "> "])))
    (expect-eq !>(&) !>((settled:dj [%mor [%txt "hi"] [%err 3] ~])))
    (expect-eq !>(|) !>((settled:dj [%mor [%txt "hi"] [%nex ~] ~])))
  ==
::
::  play dojo's side of the buffer: it takes our line, clears the
::  buffer on %ret, and must then accept our next line
++  test-clock-survives-lines
  =/  ses=session:dj  [*sole-share:sole & *@da]
  =|  dojo=sole-share:sole
  =^  one=sole-change:sole  ses  (input:dj ses ~2026.1.1 '=foo 1')
  =^  *  dojo  (~(transceive sol dojo) one)
  =^  wipe=sole-change:sole  dojo  (~(transmit sol dojo) [%set ~])
  =.  ses  (need (observe:dj ses [%mor [%txt "> =foo 1"] [%nex ~] [%det wipe] ~]))
  =/  busy=?  ready.ses
  =.  ses  (need (observe:dj ses [%pro & %$ "> "]))
  =^  two=sole-change:sole  ses  (input:dj ses ~2026.1.2 '(add foo 2)')
  =^  *  dojo  (~(transceive sol dojo) two)
  ;:  weld
    (expect-eq !>(|) !>(busy))
    (expect-eq !>("(add foo 2)") !>((tufa buf.dojo)))
    (expect-eq !>(~2026.1.2) !>(used.ses))
    (expect-eq !>(|) !>(ready.ses))
  ==
::
::  someone else edits our dojo session behind our back
++  test-rogue-edit-desyncs
  =/  ses=session:dj  [*sole-share:sole & *@da]
  =|  dojo=sole-share:sole
  =^  one=sole-change:sole  ses  (input:dj ses ~2026.1.1 '=x 7')
  =^  *  dojo  (~(transceive sol dojo) one)
  =^  wipe=sole-change:sole  dojo  (~(transmit sol dojo) [%set ~])
  =.  ses  (need (observe:dj ses [%det wipe]))
  =^  *  dojo  (~(transceive sol dojo) [[1 1] 0v0 [%set (tuba "1")]])
  =^  wipe=sole-change:sole  dojo  (~(transmit sol dojo) [%set ~])
  (expect-eq !>(~) !>((observe:dj ses [%mor [%txt "> 1"] [%det wipe] ~])))
::
::  an edit from a clock we never shared must not crash the caller
++  test-desync-is-reported
  =/  ses=session:dj  [*sole-share:sole & *@da]
  =/  bad=sole-change:sole  [[0 5] 0v0 [%set ~]]
  ;:  weld
    (expect-eq !>(~) !>((observe:dj ses [%mor [%det bad] [%pro & %$ "> "] ~])))
    (expect-eq !>(&) !>(?=(^ (observe:dj ses [%txt "fine"]))))
  ==
::
++  test-retain-evicts-stalest
  =/  full=state:dj
    %-  ~(gas by *state:dj)
    %+  turn  (gulf 1 max-sessions:dj)
    |=  n=@ud
    [(scot %ud n) `session:dj`[*sole-share:sole & (add ~2026.1.1 n)]]
  =/  [out=(list @ta) kept=state:dj]  (retain:dj full)
  ;:  weld
    (expect-eq !>(~['1']) !>(out))
    (expect-eq !>((dec max-sessions:dj)) !>(~(wyt by kept)))
    (expect-eq !>(`(list @ta)`~) !>(-:(retain:dj kept)))
  ==
--
