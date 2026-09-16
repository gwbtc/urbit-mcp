/-  mcp, spider
/+  io=strandio, aq=mcp-aqua, at=mcp-aqua-tool
^-  tool:mcp
:*  'aqua/start'
    '''
    Start a managed Spider/Aqua thread and return a runId immediately.
    Capture bounded, readable virtual-ship /effect output, not runtime slog
    hints. One run at a time; release finished runs when no longer needed.
    Default capture: blit/init/sleep/restore/kill. Other effects are optional
    metadata-only summaries (no arbitrary noun payloads).
    '''
    %-  my
    :~  ['desk' [%string 'Desk containing the thread.']]
        ['path' [%string 'Thread path, e.g. /ted/ph/add or /ted/ph/add/hoon.']]
        ['arg' [%string 'Optional raw Hoon thread argument, up to 4096 bytes.']]
        ['effects' [%array 'Optional capture tags: blit, init, sleep, restore, kill, unto, thus, request, ergo, saxo, nail, turf, send, push, doze.']]
    ==
    ~['desk' 'path']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  desk=@tas  (@tas (string:at args 'desk' ''))
    ?>  &(!=(0 desk) (lte (met 3 desk) 128))
    =/  source=@t  (string:at args 'path' '')
    =/  pax=path  (source-path:at (stab source))
    ?>  ?=([%ted @ *] pax)
    =/  term=@tas  (thread-term:at t.pax)
    ?>  (lte (met 3 term) 128)
    ;<  =bowl:spider  bind:m  get-bowl:io
    ;<  exists=?  bind:m
      (check-for-file:io [our.bowl desk da+now.bowl] (snoc (path pax) %hoon))
    ?.  exists  (pure:m !>([%error 'thread not found' ~]))
    =/  arg=@t  (string:at args 'arg' '')
    ;<  sample=vase  bind:m
      ?:  =(0 arg)  (pure:m !>(~))
      (eval-hoon:io (ream (crip (weld "[~ " (weld (trip arg) "]")))) ~)
    =/  run-id=@ta  (cat 3 'aqua-' (scot %uv (sham [eny.bowl now.bowl])))
    =/  captured=(list @tas)  (effects:at args default-effects:aq)
    ;<  ~  bind:m
      (poke-our:io %mcp-server %mcp-aqua !>([%start run-id desk term sample captured]))
    =/  encoded=@ta  (scot %uv (jam `query:aq`[run-id 0 ~ ~ | 8.192]))
    ;<  result=json  bind:m
      (scry:io json %gx /mcp-server/aqua/read/[encoded]/json)
    (pure:m !>([%result %structured result]))
==
