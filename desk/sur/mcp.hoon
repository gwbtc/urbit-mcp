|%
::
++  tool
  =<  tool
  |%
  +$  name  @t
  +$  desc  @t
  ::
  +$  parameters
    $+  mcp-tool-parameters
    (map name:parameter def:parameter)
  ::
  +$  required
    $+  mcp-tool-required-parameters
    (list name:parameter)
  ::
  +$  tool
    $+  mcp-tool
    $:  =name
        =desc
        =parameters
        =required
        =thread-builder
    ==
  ::
  +$  thread-builder
    $+  mcp-thread-builder
    $-((map name:parameter argument) shed:khan)
  ::
  +$  argument
    $+  mcp-tool-argument
    $@  ~
    $%  [%string p=@t]
        [%number p=@ud]
        [%boolean p=?]
        [%array p=(list argument)]
        [%object p=(map @t argument)]
    ==
  ::
  +$  response
    $+  mcp-tool-response
    $%  [%error message=@t data=(unit json)]
        $:  %result
            $%  [%structured =json]
                [%unstructured results=(list result)]
            ==
        ==
    ==
  ::
  +$  result
    $+  mcp-tool-result
    $%  [%text text=@t]
        [%audio data=@t mime=@t]
        [%resource-link uri=@t name=@t desc=@t mime=@t]
        $:  %image
            data=@t
            mime=@t
            annotations=(unit [audience=(list @t) priority=@rs])
        ==
        $:  %resource
            uri=@t
            mime=@t
            text=@t
            annotations=(unit [audience=(list @t) priority=@rs modified=@t])
        ==
    ==
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
        title=(unit @t)
        desc=(unit @t)
        mime-type=(unit @t)
        size=(unit @ud)
        annotations=(unit annotations)
    ==
  ::
  +$  template
    $+  mcp-resource-template
    $:  uri-template=@t
        name=@t
        title=(unit @t)
        desc=(unit @t)
        mime-type=(unit @t)
        size=(unit @ud)
        annotations=(unit annotations)
    ==
  ::
  +$  annotations
    $+  mcp-resource-annotations
    $:  audience=(list @t)
        priority=(unit @rs)
        last-modified=(unit @t)
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
        messages-builder=$-((map name:argument @t) (list message))
    ==
  ::
  ++  argument
     =<  argument
     |%
     +$  name  @t
     ::
     +$  argument
       $+  mcp-prompt-argument
       $:  =name
           desc=@t
           required=?
       ==
     --
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
