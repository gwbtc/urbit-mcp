/-  spider
|%
::
::  session management
++  id
  |%
  +$  conn  @ta  ::  http connection
  +$  last  @ta  ::  last sent event
  +$  sesh  @ta  ::  mcp session id
  --
::
+$  sessions
  $+  mcp-sessions
  (map ship (map sesh:id (map last:id (unit conn:id))))
::
++  tool
  =<  tool
  |%
  +$  tool
    $+  mcp-tool
    $:  name=@t
        desc=@t
        parameters=(map name:parameter def:parameter)
        required=(list name:parameter)
        =thread-builder
    ==
  ::
  +$  thread-builder
    $+  mcp-thread-builder
    $-((map @t json) _*form:(strand:spider ,vase))
  ::
  ++  parameter
    |%
    +$  name  @t
    ::
    +$  type
      $+  mcp-parameter-type
      $?  %array
          %boolean
          %number
          %object
          %string
      ==
    ::
    +$  def
      $+  mcp-parameter-definition
      $:  =type
          desc=@t
      ==
    --
  --
::
++  resource
  =<  resource
  |%
  +$  resource
    $+  mcp-resource
    $:  uri=@t
        name=@t
        desc=@t
        mime-type=(unit @t)
    ==
  --
::
++  prompt
  =<  prompt
  |%
  +$  prompt
    $+  mcp-prompt
    $:  name=@t
        title=@t
        desc=@t
        arguments=(list argument)
        icons=(list icon)
        messages=(list message)
    ==
  ::
  +$  argument
    $+  mcp-prompt-argument
    $:  name=@t
        desc=@t
        required=?
    ==
  ::
  +$  icon
    $+  mcp-prompt-icon
    $:  src=@t
        mime-type=@t
        sizes=(list @t)
    ==
  ::
  +$  message
    $+  mcp-prompt-message
    $:  =role
        =content
    ==
  ::
  +$  role
    $?  %assistant
        %user
    ==
  ::
  ::  XX support audio, image, resource
  +$  content
    $+  mcp-prompt-message-content
    $:  =type
        text=(unit @t)
    ==
  ::
  +$  type
    $+  mcp-prompt-message-content-type
    $?  %audio
        %image
        %resource
        %text
    ==
  --
--
