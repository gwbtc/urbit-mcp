::  the %mcp-proxy blocklist: full tool names, grouped by server
::
/-  *mcp-proxy
|_  blk=(map server-id (set feature))
++  grad  %noun
++  grow
  |%
  ++  noun  blk
  ++  json
    :-  %o
    %-  ~(run by blk)
    |=  names=(set feature)
    a+(turn ~(tap in names) |=(f=feature s+f))
  --
++  grab
  |%
  ++  noun  (map server-id (set feature))
  --
--
