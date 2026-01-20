|%
+$  name  @t
+$  desc  @t
::
+$  parameter-type
  $+  mcp-parameter-type
  $?  %array
      %boolean
      %number
      %object
      %string
  ==
::
+$  parameter-def
  $+  mcp-parameter-definition
  $:  =parameter-type
      =desc
  ==
::
+$  tool
  $+  mcp-tool
  $:  =name
      =desc
      parameters=(map name parameter-def)
      required=(list @t)
      =card:agent:gall
  ==
::
+$  resource
  $+  mcp-resource
  $:  =name
  ==
+$  prompt    *
--
