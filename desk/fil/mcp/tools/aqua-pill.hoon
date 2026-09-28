/-  mcp, spider
/+  io=strandio
/=  dojo-command  /fil/mcp/tools/dojo-command
^-  tool:mcp
:*  'aqua/pill'
    '''
    Build a brass pill, primed and cached, and load it into the %aqua
    agent. Returns Dojo's output once %aqua has the pill. Run this before
    aqua/start on a ship whose %aqua has no pill, or after changing a desk
    the virtual ships should boot with. %aqua must be running from %base.
    '''
    %-  my
    :~  :-  'desks'
        :-  %array
        '''
        Optional non-base desks to include in the pill, as an array of
        desk names (e.g. ["mcp", "landscape"]). The base desk is always
        included and need not be listed.
        '''
        :-  'base'
        :-  %string
        '''
        Optional desk to use as the pill's base desk (e.g. "base-2").
        Defaults to "base".
        '''
    ==
    ~
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    ;<  running=?  bind:m  (scry:io ? %gu /aqua/$)
    ?.  running
      %-  pure:m
      !>  ^-  response:tool:mcp
      :+  %error
        'The %aqua agent is not running. Start it with "|start %aqua" through dojo/command, then call aqua/pill again.'
      ~
    ;<  home=desk  bind:m  (scry:io desk %gd /aqua/$)
    ?.  =(%base home)
      %-  pure:m
      !>  ^-  response:tool:mcp
      :+  %error
        %-  crip
        "The %aqua agent runs from the %{(trip home)} desk; aqua/pill needs the one in %base."
      ~
    =/  bas=@tas
      =/  arg=(unit argument:tool:mcp)  (~(get by args) 'base')
      ?~  arg
        %base
      ?>  ?=([%string @t] u.arg)
      (@tas p.u.arg)
    ::  base always leads the list; drop it (and duplicates) from desks
    ::
    =/  rest=(list @tas)
      =/  arg=(unit argument:tool:mcp)  (~(get by args) 'desks')
      ?~  arg
        ~
      ?>  ?=([%array *] u.arg)
      =|  out=(list @tas)
      |-
      ?~  p.u.arg
        (flop out)
      ?>  ?=([%string @t] i.p.u.arg)
      =/  dek=@tas  (@tas p.i.p.u.arg)
      ?:  |(=(dek bas) ?=(^ (find ~[dek] out)))
        $(p.u.arg t.p.u.arg)
      $(p.u.arg t.p.u.arg, out [dek out])
    ?.  (levy `(list @tas)`[bas rest] (sane %tas))
      (pure:m !>([%error 'invalid desk name' ~]))
    =/  desk-text=tape
      %+  roll  rest
      |=  [dek=@tas out=tape]
      "{out} %{(trip dek)}"
    ::  dojo shows its next prompt only after %aqua acks the poke
    ::
    %-  thread-builder.dojo-command
    %-  ~(gas by *(map name:parameter:tool:mcp argument:tool:mcp))
    :~  :-  'command'
        :-  %string
        %-  crip
        ":aqua &pill +pill/brass %{(trip bas)}{desk-text}, =prime .y, =cache .y"
        ['timeout-seconds' [%number 600]]
    ==
==
