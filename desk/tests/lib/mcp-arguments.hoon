/-  mcp
/+  *test, ma=mcp-arguments
|%
++  test-unsigned-json-integers
  =/  args=(map @t json)
    (my ~[['a' n+'0'] ['b' n+'999'] ['c' n+'1000'] ['d' n+'8192'] ['e' n+'32768'] ['f' n+'1000000']])
  =/  got=(unit (map @t argument:tool:mcp))  (parse-args:ma args)
  =/  want=(map @t argument:tool:mcp)
    (my ~[['a' [%number 0]] ['b' [%number 999]] ['c' [%number 1.000]] ['d' [%number 8.192]] ['e' [%number 32.768]] ['f' [%number 1.000.000]]])
  (expect-eq !>(`want) !>(got))
++  test-invalid-json-integers
  =/  inputs=(list @ta)  ~['-1' '1.5' '1e3' '32.768']
  %-  zing
  %+  turn  inputs
  |=  txt=@ta
  (expect-eq !>(~) !>((parse-args:ma (my ~[['n' n+txt]]))))
++  test-nested-json-integers
  =/  got=(unit (map @t argument:tool:mcp))
    (parse-args:ma (my ~[['array' a+~[n+'32768']] ['object' (pairs:enjs:format ~[['n' n+'1000']])]]))
  ?>  ?=(^ got)
  %+  weld
    (expect-eq !>([%array ~[[%number 32.768]]]) !>((~(got by u.got) 'array')))
  (expect-eq !>([%object (my ~[['n' [%number 1.000]]])]) !>((~(got by u.got) 'object')))
--
