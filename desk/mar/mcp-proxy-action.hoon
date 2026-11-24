::  json omits %call-tool; only %mcp-server sends that, as a noun
::
/-  *mcp-proxy
|_  act=action
++  grad  %noun
++  grow
  |%
  ++  noun  act
  --
++  grab
  |%
  ++  noun  action
  ++  json
    |=  jon=^json
    ^-  action
    =,  dejs:format
    ;;  action
    %.  jon
    %-  of
    :~  :-  %add-mcp-server
        (ot ~[id+so url+so headers+(ar (ot ~[key+so value+so]))])
        [%delete-mcp-server (ot ~[id+so])]
        [%refresh-mcp-server (ot ~[id+(mu so)])]
        [%block-tool (ot ~[id+so tool+so])]
        [%unblock-tool (ot ~[id+so tool+so])]
    ==
  --
--
