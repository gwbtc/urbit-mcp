/+  dbug, verb, default-agent
::
::  state definition core
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0
  $:  %0
      values=(list @)
  ==
+$  card  card:agent:gall
--
%+  verb  |
%-  agent:dbug
=|  state-0
=*  state  -
::
::  agent
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
++  on-init
  ^-  (quip card _this)
  `this
::
++  on-save   !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  :-  ^-  (list card)
      ~
  %=  this
    state  !<(state-0 old)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark
    (on-poke:def mark vase)
  ::
      %noun
    :-  ~
    %=  this
      values  :-(!<(@ud vase) values)
    ==
  ==
::
++  on-peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+  pole
    (on-peek:def pole)
  ::
  ::  .^(json %gx /=/this-desk/=/values/json)
      [%x %values ~]
    %-  some
    %-  some
    :-  %json
    !>  ^-  json
    %-  frond:enjs:format
    :-  'values'
    :-  %a
    (turn values |=(val=@ n+(scot %ud val)))
  ::
  ::  .^(json %gx /=/this-desk/=/value/0/json)
      [%x %value pos=@ta ~]
    %-  some
    %-  some
    :-  %json
    !>  ^-  json
    %-  frond:enjs:format
    :-  'value'
    :-  %n
    (scot %ud (snag (slav %ud pos.pole) values))
  ==
::
++  on-watch
  |=  =(pole knot)
  ^-  (quip card _this)
  ?+  pole
    (on-watch:def pole)
  ::
      [%values ~]
    `this
  ==
::
++  on-arvo   on-arvo:def
++  on-leave  on-leave:def
++  on-agent  on-agent:def
++  on-fail   on-fail:def
--
