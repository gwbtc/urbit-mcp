/-  spider
/+  strandio
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
+$  thread-builder
  $+  mcp-thread-builder
  $-((map @t json) _*form:(strand:spider ,vase))
::
+$  tool
  $+  mcp-tool
  $:  =name
      =desc
      parameters=(map name parameter-def)
      required=(list @t)
      =thread-builder
  ==
::
+$  resource
  $+  mcp-resource
  $:  uri=@t
      =name
      =desc
      mime-type=(unit @t)
  ==
+$  prompt-argument
  $+  mcp-prompt-argument
  $:  =name
      parameter-type=(unit parameter-type)
      =desc
      required=?
  ==
::
+$  prompt
  $+  mcp-prompt
  $:  =name
      title=@t
      =desc
      arguments=(list prompt-argument)
  ==
--
