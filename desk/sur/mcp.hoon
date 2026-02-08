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
::
+$  prompt-argument
  $+  mcp-prompt-argument
  $:  =name
      =desc
      required=?
  ==
::
+$  prompt-icon
  $+  mcp-prompt-icon
  $:  src=@t
      mime-type=@t
      sizes=(list @t)
  ==
::
+$  prompt-message-type
  $+  mcp-prompt-message-type
  $?  %audio
      %image
      %resource
      %text
  ==
::
+$  prompt-message-content
  $+  mcp-prompt-message-content
  $:  type=@tas
      text=(unit @t)
  ==
::
+$  prompt-messaage-role
  $+  mcp-prompt-message-role
  $?  %assistant
      %user
  ==
+$  prompt-message
  $+  mcp-prompt-message
  $:  role=@tas
      content=prompt-message-content
  ==
::
+$  prompt
  $+  mcp-prompt
  $:  =name
      title=@t
      =desc
      arguments=(list prompt-argument)
      icons=(list prompt-icon)
      messages=(list prompt-message)
  ==
--
