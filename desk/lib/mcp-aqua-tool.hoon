/-  mcp
/+  aq=mcp-aqua
|%
+$  args  (map @t argument:tool:mcp)
::
++  thread-term
  |=  pax=path
  ^-  @tas
  =|  out=tape
  |-
  ?~  pax
    (@tas (crip out))
  $(pax t.pax, out ?:(=(~ out) (trip i.pax) :(weld out "-" (trip i.pax))))
::
++  source-path
  |=  pax=path
  ^-  path
  ?~  pax
    ~
  ?~  t.pax
    ?:(=(%hoon i.pax) ~ pax)
  [i.pax $(pax t.pax)]
::
++  string
  |=  [args=args key=@t default=@t]
  ^-  @t
  =/  got=(unit argument:tool:mcp)  (~(get by args) key)
  ?~  got
    default
  ?>  ?=(%string -.u.got)
  ?>  (lte (met 3 p.u.got) 4.096)
  p.u.got
::
++  number
  |=  [args=args key=@t default=@ud]
  ^-  @ud
  =/  got=(unit argument:tool:mcp)  (~(get by args) key)
  ?~  got
    default
  ?>  ?=(%number -.u.got)
  p.u.got
::
++  boolean
  |=  [args=args key=@t default=?]
  ^-  ?
  =/  got=(unit argument:tool:mcp)  (~(get by args) key)
  ?~  got
    default
  ?>  ?=(%boolean -.u.got)
  p.u.got
::
++  strings
  |=  [args=args key=@t]
  ^-  (list @t)
  =/  got=(unit argument:tool:mcp)  (~(get by args) key)
  ?~  got
    ~
  ?>  ?=(%array -.u.got)
  ?>  ?=(~ (slag 32 p.u.got))
  %+  turn  p.u.got
  |=  v=argument:tool:mcp
  ^-  @t
  ?>  ?=(%string -.v)
  ?>  (lte (met 3 p.v) 128)
  p.v
::
++  effects
  |=  [args=args default=(list @tas)]
  ^-  (list @tas)
  ?.  (~(has by args) 'effects')  default
  =/  out=(list @tas)  (turn (strings args 'effects') |=(s=@t (@tas s)))
  ?>  (lte (lent out) 16)
  ?>  (levy out |=(e=@tas (matches-effect:aq supported-effects:aq e)))
  out
::
++  id
  |=  args=args
  ^-  @ta
  =/  out=@t  (string args 'runId' '')
  ?>  &(!=(0 out) (lte (met 3 out) 128))
  ::  IDs are path-safe cords, not arbitrary path fragments.
  ?>  (levy (trip out) |=(c=@tD ?|(&((gte c 'a') (lte c 'z')) &((gte c '0') (lte c '9')) =(c '-') =(c '.') =(c '_'))))
  (@ta out)
::
++  query
  |=  args=args
  ^-  query:aq
  :*  (id args)
      (number args 'cursor' 0)
      (turn (strings args 'ships') |=(s=@t (@p (slav %p s))))
      (effects args ~)
      (boolean args 'includePrompts' |)
      (number args 'maxBytes' 8.192)
  ==
--
