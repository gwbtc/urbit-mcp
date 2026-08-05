/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'mcp/import-mcp-prompts'
    'Import MCP Prompts from a desk.'
    %-  my
    :~  ['desk' [%string 'Desk to import MCP Prompts from.']]
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
    ;<  before=(list prompt:mcp)  bind:m
      (scry:io (list prompt:mcp) %gx /mcp-server/mcp/prompts/noun)
    =/  agents=(list dude:gall)
      %+  murn
        ~(tap in .^((set [dude:gall ?]) %ge /(scot %p our.bowl)/[p.u.dek]/(scot %da now.bowl)/$))
      |=  [=dude:gall live=?]
      ^-  (unit dude:gall)
      ?.  live
        ~
      =/  result=(each * (list tank))
        %-  mule
        |.  .^((list prompt:mcp) %gx /(scot %p our.bowl)/[dude]/(scot %da now.bowl)/mcp/prompts/noun)
      ?.  -.result
        ~
      ?~  ;;((list prompt:mcp) p.result)
        ~
      `dude
    ;<  ~  bind:m
      %-  send-raw-cards:io
      %+  turn  agents
      |=  =dude:gall
      ^-  card:agent:gall
      [%pass /import-prompts %agent [our.bowl %mcp-server] %poke %import-prompts !>(dude)]
    =/  take-acks
      |=  remaining=(list dude:gall)
      =/  am  (strand:spider ,~)
      ^-  form:am
      ?~  remaining
        (pure:am ~)
      ;<  ~  bind:am  (take-poke-ack:io /import-prompts)
      $(remaining t.remaining)
    ;<  ~  bind:m  (take-acks agents)
    ;<  after=(list prompt:mcp)  bind:m
      (scry:io (list prompt:mcp) %gx /mcp-server/mcp/prompts/noun)
    =/  added=(list prompt:mcp)
      %+  murn  after
      |=  new=prompt:mcp
      ^-  (unit prompt:mcp)
      ?:  %+  lien  before
          |=  old=prompt:mcp
          =(name.new name.old)
        ~
      `new
    ::
    ::  refreshed: same name as before, but the entry changed
    =/  refreshed=(list prompt:mcp)
      %+  murn  after
      |=  new=prompt:mcp
      ^-  (unit prompt:mcp)
      ?.  %+  lien  before
          |=  old=prompt:mcp
          &(=(name.new name.old) !=(new old))
        ~
      `new
    %-  pure:m
    !>  ^-  response:tool:mcp
    :-  %result
    :-  %structured
    %-  pairs:enjs:format
    %-  zing
    :~  :~  [%imported-prompts a+(turn added |=(=prompt:mcp s+name.prompt))]
        ==
        ?~  refreshed  ~
        :~  [%refreshed-prompts a+(turn refreshed |=(=prompt:mcp s+name.prompt))]
    ==  ==
==
