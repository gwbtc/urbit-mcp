::  pure state for the dojo %sole sessions %mcp-server holds open.
::  dojo drops a session when its subscriber leaves, and a tool thread
::  cannot keep a subscription past its own run, so the agent holds
::  the subscription and the buffer clock; threads watch a relay.
/-  sole
/+  sol=sole
|%
+$  session
  $:  ::  shared-buffer clock; dojo crashes on edits that lack it
      say=sole-share:sole
      ::  dojo is at a prompt and will take a line
      ready=?
      ::  time of last input; the stalest session is evicted first
      used=@da
  ==
::
+$  state  (map @ta session)
::
+$  action
  $%  ::  run one line
      [%input ses=@ta txt=@t]
      ::  cancel running work and any half-entered expression
      [%clear ses=@ta]
      ::  drop the session
      [%close ses=@ta]
  ==
::
++  max-sessions    8
++  max-name-bytes  64
::
::  +valid-name: session names are client input used as path knots
++  valid-name
  |=  ses=@t
  ^-  ?
  ?&  !=('' ses)
      (lte (met 3 ses) max-name-bytes)
      ((sane %ta) ses)
  ==
::
::  +dojo-ses: name of the session on dojo's side; the prefix keeps
::  clients off drum's own sessions, such as the default console
++  dojo-ses
  |=  ses=@ta
  ^-  @ta
  (cat 3 'mcp-' ses)
::
::  +settled: dojo ends each line with a prompt or a parse error
++  settled
  |=  fec=sole-effect:sole
  ^-  ?
  ?+  -.fec  |
    %pro  &
    %err  &
    %mor  (lien p.fec settled)
  ==
::
::  +absorb: fold dojo's buffer edits into our side of the clock
++  absorb
  |=  [say=sole-share:sole fec=sole-effect:sole]
  ^-  sole-share:sole
  ?+  -.fec  say
    %mor  (roll p.fec |=([f=sole-effect:sole s=_say] (absorb s f)))
    %det  +:(~(transceive sol say) +.fec)
  ==
::
::  +observe: ~ if dojo's edit does not fit our clock. +transceive
::  crashes on a mismatch, and every later edit would crash too, so
::  the caller should drop the session
++  observe
  |=  [s=session fec=sole-effect:sole]
  ^-  (unit session)
  =/  say  (mule |.((absorb say.s fec)))
  ?:  ?=(%| -.say)
    ~
  `s(say p.say, ready |(ready.s (settled fec)))
::
::  +input: replace the buffer with .txt; the caller follows with %ret
++  input
  |=  [s=session now=@da txt=@t]
  ^-  [sole-change:sole session]
  =^  cal  say.s  (~(transmit sol say.s) [%set (tuba (trip txt))])
  [cal s(ready |, used now)]
::
::  +retain: evict the stalest sessions until one more fits
++  retain
  |=  s=state
  ^-  [(list @ta) state]
  =|  out=(list @ta)
  |-
  ?:  (lth ~(wyt by s) max-sessions)
    [out s]
  =/  old=@ta
    =<  p
    %+  roll  ~(tap by s)
    |=  [a=(pair @ta session) b=(pair @ta session)]
    ?:(|(=('' p.b) (lth used.q.a used.q.b)) a b)
  $(out [old out], s (~(del by s) old))
--
