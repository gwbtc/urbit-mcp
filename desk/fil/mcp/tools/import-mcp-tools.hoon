/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'mcp/import-mcp-tools'
    'Import MCP Tools from a desk.'
    %-  my
    :~  ['desk' [%string 'Desk to import MCP Tools from.']]
    ==
    ~['desk']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  dek=(unit argument:tool:mcp)  (~(get by args) 'desk')
    ?~  dek
      (pure:m !>([%error %missing-desk ~]))
    ?>  ?=([%string *] u.dek)
    ;<  =bowl:rand  bind:m  get-bowl:io
    ;<  before=(list tool:mcp)  bind:m
      (scry:io (list tool:mcp) %gx /mcp-server/mcp/tools/noun)
    =/  agents=(list dude:gall)
      %+  murn
        ~(tap in .^((set [dude:gall ?]) %ge /(scot %p our.bowl)/[p.u.dek]/(scot %da now.bowl)/$))
      |=  [=dude:gall live=?]
      ^-  (unit dude:gall)
      ?.  live
        ~
      =/  result=(each * (list tank))
        %-  mule
        |.  .^((list tool:mcp) %gx /(scot %p our.bowl)/[dude]/(scot %da now.bowl)/mcp/tools/noun)
      ?.  -.result
        ~
      ?~  ;;((list tool:mcp) p.result)
        ~
      `dude
    ;<  ~  bind:m
      %-  send-raw-cards:io
      %+  turn  agents
      |=  =dude:gall
      ^-  card:agent:gall
      [%pass /import-tools %agent [our.bowl %mcp-server] %poke %import-tools !>(dude)]
    =/  take-acks
      |=  remaining=(list dude:gall)
      =/  am  (strand:spider ,~)
      ^-  form:am
      ?~  remaining
        (pure:am ~)
      ;<  ~  bind:am  (take-poke-ack:io /import-tools)
      $(remaining t.remaining)
    ;<  ~  bind:m  (take-acks agents)
    ;<  after=(list tool:mcp)  bind:m
      (scry:io (list tool:mcp) %gx /mcp-server/mcp/tools/noun)
    =/  added=(list tool:mcp)
      %+  murn  after
      |=  new=tool:mcp
      ^-  (unit tool:mcp)
      ?:  %+  lien  before
          |=  old=tool:mcp
          =(name.new name.old)
        ~
      `new
    ::
    ::  refreshed: same name as before, but the entry changed
    =/  refreshed=(list tool:mcp)
      %+  murn  after
      |=  new=tool:mcp
      ^-  (unit tool:mcp)
      ?.  %+  lien  before
          |=  old=tool:mcp
          &(=(name.new name.old) !=(new old))
        ~
      `new
    %-  pure:m
    !>  ^-  response:tool:mcp
    :-  %result
    :-  %structured
    %-  pairs:enjs:format
    %-  zing
    :~  :~  [%imported-tools a+(turn added |=(=tool:mcp s+name.tool))]
        ==
        ?~  refreshed  ~
        :~  [%refreshed-tools a+(turn refreshed |=(=tool:mcp s+name.tool))]
    ==  ==
==
