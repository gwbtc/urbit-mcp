/-  mcp, spider
/+  *test, ml=mcp
=>
::
::  mock data
|%
++  sample-tool
  ^-  tool:mcp
  :*  name='test-tool'
      desc='A test tool'
      parameters=(my ~[['param1' [%string 'Test parameter']]])
      required=~['param1']
      ^=  thread-builder
      |=  *
      ^-  shed:khan
      =/  m  (strand:spider ,vase)
      %-  pure:m
      !>  ^-  json
      %-  pairs:enjs:format
      :~  ['type' s+'text']
          ['text' s+'Success!']
      ==
  ==
::
++  sample-resource
  ^-  resource:mcp
  :*  uri='test://example'
      name='Test Resource'
      desc='A test resource'
      mime-type=`'text/plain'
  ==
--
::
::  tests
|%
++  test-rpc-result
  %-  expect-eq
  :_  !>  (result:rpc:ml s+'test' `n+~.0)
  !>  ^-  json
  %-  pairs:enjs:format
  :~  ['jsonrpc' s+'2.0']
      ['result' s+'test']
      ['id' n+~.0]
  ==
::
++  test-mcp-tools-to-json
  %-  expect-eq
  :_  !>  (mcp-tools-to-json:ml (sy ~[sample-tool]))
  !>  ^-  json
  %-  pairs:enjs:format
  :~  :-  'tools'
      :-  %a
      :~  %-  pairs:enjs:format
          :~  ['name' s+'test-tool']
              ['description' s+'A test tool']
              :-  'inputSchema'
              %-  pairs:enjs:format
              :~  ['type' s+'object']
                  :-  'properties'
                  %-  pairs:enjs:format
                  :~  :-  'param1'
                      %-  pairs:enjs:format
                      :~  ['type' s+'string']
                          ['description' s+'Test parameter']
                      ==
                  ==
                  :-  'required'
                  :-  %a
                  :~  s+'param1'
  ==  ==  ==  ==  ==
--
