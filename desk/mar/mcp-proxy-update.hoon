/-  *mcp-proxy
|_  upd=update
++  grad  %noun
++  grow
  |%
  ++  noun  upd
  ++  json
    ?-    -.upd
        %tools-changed
      (frond:enjs:format 'tools-changed' ~)
    ::
        %tool-result
      %+  frond:enjs:format  'tool-result'
      ?-    -.result.upd
          %result
        (frond:enjs:format 'result' json.result.upd)
      ::
          %error
        %+  frond:enjs:format  'error'
        %-  pairs:enjs:format
        :*  ['code' n+code.result.upd]
            ['message' s+message.result.upd]
            ?~(data.result.upd ~ ['data' u.data.result.upd]~)
        ==
      ==
    ==
  --
++  grab
  |%
  ++  noun  update
  --
--
