::  Convert JSON tool arguments without interpreting JSON numbers as @ud text.
::
/-  mcp
|%
++  parse-arg
  |=  jon=json
  ^-  argument:tool:mcp
  ?+  jon  ~
    [%a *]  [%array (turn p.jon parse-arg)]
    [%b ?]  [%boolean p.jon]
    [%o *]  [%object (~(run by p.jon) parse-arg)]
    [%n @ta]  [%number (need (rush p.jon dim:ag))]
    [%s @t]  [%string p.jon]
  ==
::
++  parse-args
  |=  args=(map @t json)
  ^-  (unit (map @t argument:tool:mcp))
  =/  result  (mule |.((~(run by args) parse-arg)))
  ?-  -.result
    %|  ~
    %&  `p.result
  ==
--
