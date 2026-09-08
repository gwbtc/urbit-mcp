/-  mcp, sole, spider
/+  io=strandio, libstrand=strand
=,  sole
=,  strand=strand:libstrand
=>
|%
++  print-tang-to-wain
  |=  =tang
  ^-  wain
  %-  zing
  %+  turn
    tang
  |=  =tank
  %+  turn
    (wash [0 80] tank)
  |=  =tape
  (crip tape)
::
++  join-wain
  |=  =wain
  ^-  @t
  =/  out=tape  ~
  |-
  ?~  wain
    (crip out)
  $(wain t.wain, out (weld out (weld (trip i.wain) ?~(t.wain "" "\0a"))))
::
++  effect-lines
  |=  fec=sole-effect
  ^-  wain
  ?+  -.fec  ~
    %mor
  %-  zing
  %+  turn
    p.fec
  effect-lines
::
    %txt  [(crip p.fec) ~]
    %tan  (print-tang-to-wain p.fec)
    %err  [(crip "dojo parse error at {<p.fec>}") ~]
    %url  [p.fec ~]
  ==
::
++  log-lines
  |=  log=told:dill
  ^-  wain
  ?-  -.log
      %crud
    %-  zing
    %+  turn
      ^-  wall
      (zing (turn (flop q.log) (cury wash [0 80])))
    |=  =tape
    [(crip tape) ~]
  ::
      %talk
    %-  zing
    %+  turn
      ^-  wall
      (zing (turn p.log (cury wash [0 80])))
    |=  =tape
    [(crip tape) ~]
  ::
      %text  [(crip p.log) ~]
  ==
::
::  +effect-saves: extract file-save effects. For a console session
::  drum forwards these to the runtime as blits and the terminal
::  writes them under <pier>/.urb/put; headless sole sessions like
::  ours must forward them by hand or the file is silently lost.
::
++  effect-saves
  |=  fec=sole-effect
  ^-  (list [=path atom=@])
  ?+  -.fec  ~
    %mor  (zing (turn p.fec effect-saves))
    %sav  [[p.fec q.fec] ~]
    %sag  [[p.fec (jam q.fec)] ~]
  ==
::
++  is-pro
  |=  fec=sole-effect
  ^-  ?
  ?+  -.fec  |
    %pro  &
    %mor  (lien p.fec is-pro)
  ==
::
++  safe-set-timeout
  |*  computation-result=mold
  =/  m  (strand ,computation-result)
  |=  [time=@dr computation=form:m]
  ^-  form:m
  ;<  now=@da  bind:m  get-time:io
  =/  when  (add now time)
  =/  =card:agent:gall
    [%pass /timeout/(scot %da when) %arvo %b %wait when]
  ;<  ~  bind:m  (send-raw-card:io card)
  |=  tin=strand-input:strand
  =*  loop  $
  ?:  ?&  ?=([~ %sign [%timeout @ ~] %behn %wake *] in.tin)
          =((scot %da when) i.t.wire.u.in.tin)
      ==
    `[%done ~]
  =/  c-res  (computation tin)
  ?:  ?=(%cont -.next.c-res)
    c-res(self.next ..loop(computation self.next.c-res))
  ?:  ?=(%done -.next.c-res)
    =/  =card:agent:gall
      [%pass /timeout/(scot %da when) %arvo %b %rest when]
    c-res(cards [card cards.c-res])
  c-res
::
++  take-sole-effect
  |=  =wire
  =/  m  (strand ,sole-effect)
  ^-  form:m
  |=  tin=strand-input:strand
  ?+  in.tin  `[%skip ~]
      ~  `[%wait ~]
      [~ %agent * %fact *]
    ?.  =(watch+wire wire.u.in.tin)
      `[%skip ~]
    ?.  =(%sole-effect p.cage.sign.u.in.tin)
      `[%skip ~]
    `[%done !<(sole-effect q.cage.sign.u.in.tin)]
  ==
::
++  take-output
  |=  =wire
  =/  m  (strand ,(each sole-effect told:dill))
  ^-  form:m
  |=  tin=strand-input:strand
  ?+  in.tin  `[%skip ~]
      ~  `[%wait ~]
      [~ %agent * %fact *]
    ?.  =(watch+wire wire.u.in.tin)
      `[%skip ~]
    ?.  =(%sole-effect p.cage.sign.u.in.tin)
      `[%skip ~]
    `[%done [%& !<(sole-effect q.cage.sign.u.in.tin)]]
  ::
      [~ %sign *]
    ?.  =(/dill-logs wire.u.in.tin)
      `[%skip ~]
    ?.  ?=([%dill %logs *] sign-arvo.u.in.tin)
      `[%skip ~]
    =/  [%dill %logs =told:dill]  sign-arvo.u.in.tin
    `[%done [%| told]]
  ==
::
++  collect-until-pro
  |=  [=wire limit=@dr]
  =/  m  (strand ,[(list cord) ?])
  =|  lines=(list cord)
  |-  ^-  form:m
  ;<  maybe=(unit sole-effect)  bind:m
    %+  (safe-set-timeout (unit sole-effect))  limit
    =/  m  (strand ,(unit sole-effect))
    ^-  form:m
    ;<  fec=sole-effect  bind:m  (take-sole-effect wire)
    (pure:m `fec)
  ?~  maybe
    (pure:m [lines |])
  =/  extra=wain  (effect-lines u.maybe)
  =/  done=?      (is-pro u.maybe)
  =.  lines       (weld lines extra)
  ?:  done
    (pure:m [lines &])
  $(lines lines)
::
::  +forward-saves: poke each save through drum so the runtime
::  terminal writes the file under <pier>/.urb/put.
::
++  forward-saves
  |=  saves=(list [=path atom=@])
  =/  m  (strand ,~)
  |-  ^-  form:m
  ?~  saves
    (pure:m ~)
  ;<  ~  bind:m
    (poke-our:io %hood %drum-put !>([path.i.saves atom.i.saves]))
  $(saves t.saves)
::
::  +unix-name: where the runtime writes a saved file,
::  e.g. /test/pill -> .urb/put/test.pill
::
++  unix-name
  |=  =path
  ^-  @t
  %-  crip
  =/  file=tape
    ?~  path  ""
    %+  roll  `(list @ta)`t.path
    |=([seg=@ta out=_(trip i.path)] "{out}.{(trip seg)}")
  ".urb/put/{file}"
::
::  +collect-output-until-pro: gather output until Dojo reports its
::  next prompt, which means the command finished. Returning on mere
::  idleness breaks long-running commands: we would leave the %sole
::  subscription while the command still runs, and Dojo's later %fact
::  into the dead subscription desyncs it from drum. The timeout only
::  caps silence between effects.
::
++  collect-output-until-pro
  |=  [=wire limit=@dr]
  =/  m  (strand ,[lines=(list cord) saved=(list path)])
  =|  lines=(list cord)
  =|  saved=(list path)
  |-  ^-  form:m
  ;<  maybe=(unit (each sole-effect told:dill))  bind:m
    %+  (safe-set-timeout (unit (each sole-effect told:dill)))  limit
    =/  m  (strand ,(unit (each sole-effect told:dill)))
    ^-  form:m
    ;<  out=(each sole-effect told:dill)  bind:m  (take-output wire)
    (pure:m `out)
  ?~  maybe
    (pure:m [lines saved])
  ?-    -.u.maybe
      %&
    =/  saves=(list [=path atom=@])  (effect-saves p.u.maybe)
    ;<  ~  bind:m  (forward-saves saves)
    =.  lines  (weld lines (effect-lines p.u.maybe))
    =.  saved  (weld saved (turn saves head))
    ?:  (is-pro p.u.maybe)
      (pure:m [lines saved])
    $
  ::
      %|
    $(lines (weld lines (log-lines p.u.maybe)))
  ==
--
::
^-  tool:mcp
:*  'dojo/command'
  '''
  Run one string in Dojo through the %sole command-line protocol and return
  the text emitted before Dojo reports the next prompt.
  '''
  %-  my
  :~  :-  'command'
      :-  %string
      '''
      The Dojo input to run, e.g. "(add 2 2)" or "'hello world'".
      '''
      :-  'timeout-seconds'
      :-  %number
      '''
      Optional timeout in seconds. Caps the silence between pieces of
      Dojo output, not the total run time; collection ends when Dojo
      shows its next prompt. Defaults to 10.
      '''
      :-  'sole-id'
      :-  %string
      '''
      Optional %sole session name to use instead of a fresh random one,
      e.g. the sole-id returned by an earlier call. Reusing a session
      lets later commands see Dojo state set by earlier ones.
      '''
  ==
  ~['command']
  ^-  thread-builder:tool:mcp
  |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
  ^-  shed:khan
  =/  m  (strand:spider ,vase)
  ^-  form:m
  =/  cmd=(unit argument:tool:mcp)  (~(get by args) 'command')
  ?~  cmd
    (pure:m !>([%error %missing-command ~]))
  ?>  ?=([%string @t] u.cmd)
  =/  timeout=@dr
    =/  arg=(unit argument:tool:mcp)  (~(get by args) 'timeout-seconds')
    ?~  arg
      ~s10
    ?>  ?=([%number @] u.arg)
    (mul ~s1 p.u.arg)
  ;<  bowl=bowl:rand  bind:m  get-bowl:io
  =/  ses=@ta
    =/  arg=(unit argument:tool:mcp)  (~(get by args) 'sole-id')
    ?~  arg
      (cat 3 'mcp-dojo-' (scot %uv (sham eny.bowl)))
    ?>  ?=([%string @t] u.arg)
    `@ta`p.u.arg
  =/  wire=wire   /dojo-command/[ses]
  ::  %mcp-server holds the %sole subscription so the session outlives
  ::  this thread; a fresh session greets us with a prompt to drain
  ;<  held=?  bind:m  (scry:io ? /gx/mcp-server/dojo/[ses]/noun)
  ;<  ~  bind:m  (watch-our:io wire %mcp-server /dojo/[ses])
  ;<  *  bind:m
    ?:  held
      (pure:(strand ,[(list cord) ?]) [~ &])
    (collect-until-pro wire ~s5)
  ;<  ~  bind:m
    (send-raw-card:io [%pass /dill-logs %arvo %d %logs `~])
  ;<  ~  bind:m
    (poke-our:io %mcp-server %noun !>([%dojo-input ses p.u.cmd]))
  ;<  [result=(list cord) saved=(list path)]  bind:m
    (collect-output-until-pro wire timeout)
  ;<  ~  bind:m
    (send-raw-card:io [%pass /dill-logs %arvo %d %logs ~])
  %-  pure:m
  !>  ^-  response:tool:mcp
  :-  %result
  :-  %structured
  %-  pairs:enjs:format
  %+  weld
    ^-  (list [@t json])
    :~  ['dojo-output' s+(of-wain:format result)]
        ['sole-id' s+ses]
    ==
  ^-  (list [@t json])
  ?~  saved  ~
  ['saved-files' a+(turn saved |=(=path s+(unix-name path)))]~
==
