::
::  JSON RPC 2.0
::
::  id is the raw json-rpc request id: a string, a number, or
::  null (~) when the request's id was unreadable
|%
+$  response
  $%  [%result id=json result=json]
      [%error id=json code=@ta message=@t data=(unit json)]
  ==
--
