/-  *json-rpc
|%
++  rpc
  |%
  ++  make-response
    |=  res=response
    ^-  json
    ?-    -.res
        %result
      %-  pairs:enjs:format
      :~  ['id' id.res]
          ['jsonrpc' s+'2.0']
          ['result' result.res]
      ==
    ::
        %error
      %-  pairs:enjs:format
      :~  ['id' id.res]
          ['jsonrpc' s+'2.0']
          :-  'error'
          %-  pairs:enjs:format
          %+  welp
            :~  ['code' n+code.res]
                ['message' s+message.res]
            ==
          ?~  data.res
            ~
          :~  ['data' u.data.res]
          ==
      ==
    ==
  ++  result
    |=  [id=json res=json]
    (make-response [%result id res])
  ++  error
    |%
    ++  code
      |%
      ++  parse-error          ~.-32700
      ++  invalid-request      ~.-32600
      ++  method-not-found     ~.-32601
      ++  invalid-params       ~.-32602
      ++  internal-error       ~.-32603
      ++  header-mismatch      ~.-32020
      ++  missing-capability   ~.-32021
      ++  unsupported-version  ~.-32022
      --
    ++  parse
      |=  [id=json message=@t data=(unit json)]
      (make-response [%error id parse-error:code message data])
    ++  request
      |=  [id=json message=@t data=(unit json)]
      (make-response [%error id invalid-request:code message data])
    ++  method
      |=  [id=json message=@t data=(unit json)]
      (make-response [%error id method-not-found:code message data])
    ++  params
      |=  [id=json message=@t data=(unit json)]
      (make-response [%error id invalid-params:code message data])
    ++  internal
      |=  [id=json message=@t data=(unit json)]
      (make-response [%error id internal-error:code message data])
    ++  header
      |=  [id=json message=@t data=(unit json)]
      (make-response [%error id header-mismatch:code message data])
    ++  version
      |=  [id=json requested=@t supported=(list @t)]
      %-  make-response
      :*  %error  id  unsupported-version:code
          'Unsupported protocol version'
          :-  ~
          %-  pairs:enjs:format
          :~  ['supported' a+(turn supported |=(v=@t s+v))]
              ['requested' s+requested]
          ==
      ==
    --
  --
--
