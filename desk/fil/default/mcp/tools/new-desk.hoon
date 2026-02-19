/-  mcp, spider
/+  io=strandio
^-  tool:mcp
:*  'new-desk'
    '''
    Create a new desk with some default provisions.
    '''
    %-  my
    :~  :-  'desk'
        :-  %string
        '''
        Name of the desk to create (e.g. 'my-app').
        '''
    ==
    ~['desk']
    ^-  thread-builder:tool:mcp
    |=  args=(map name:parameter:tool:mcp argument:tool:mcp)
    ^-  shed:khan
    =/  m  (strand:spider ,vase)
    ^-  form:m
    =/  desk-arg=(unit argument:tool:mcp)  (~(get by args) 'desk')
    ?~  desk-arg
      ~|(%missing-desk !!)
    ?>  ?=([%string @t] u.desk-arg)
    =/  dek=@tas  (@tas p.u.desk-arg)
    ;<  =bowl:rand  bind:m  get-bowl:io
    ;<  ~  bind:m
      %:  send-raw-card:io
          %pass   /make-new-desk
          %agent  [our.bowl %hood]
          %poke   %helm-pass
          !>  ^-  note-arvo
          %^    new-desk:cloy
             dek
            ~
          %-  ~(gas by *(map path page:clay))
          |^  ^-  (list [path page:clay])
              %+  welp
                ::   build agent
                :~  %+  file-page
                      /[q.byk.bowl]/fil/gall/single/hoon
                    /app/[dek]/hoon
                ==
              ::  import dependencies
              %-  turn
              :_  make-page
              ^-  (list path)
              :~  /base/sys/kelvin
                  /base/mar/bill/hoon
                  /base/mar/hoon/hoon
                  /base/mar/mime/hoon
                  /base/mar/noun/hoon
                  /[q.byk.bowl]/lib/dbug/hoon
                  /[q.byk.bowl]/lib/verb/hoon
                  /[q.byk.bowl]/sur/verb/hoon
                  /[q.byk.bowl]/mar/kelvin/hoon
                  /[q.byk.bowl]/lib/skeleton/hoon
                  /[q.byk.bowl]/lib/default-agent/hoon
              ==
          ::
          ++  make-page
            |=  pax=path
            ^-  [path page:clay]
            ?>  ?=([@tas *] pax)
            :-  t.pax
            :-  (rear pax)
            ~|  [%missing-file pax]
            .^  noun
                %cx
                (scot %p our.bowl)
                i.pax
                (scot %da now.bowl)
                t.pax
            ==
          ::
          ++  file-page
            |=  [src=path dst=path]
            ^-  [path page:clay]
            ?>  ?=([@tas *] src)
            ?>  ?=([@tas *] dst)
            ?>  =((rear src) (rear dst))
            :-  dst
            :-  (rear src)
            ~|  [%missing-file src]
            .^  noun
                %cx
                (scot %p our.bowl)
                i.src
                (scot %da now.bowl)
                t.src
            ==
          --
      ==
    ::  ;<  ~  bind:m  (take-poke-ack:io /make-new-desk)
    ::  write desk.bill
    ;<  ~  bind:m
      %:  send-raw-card:io
          %pass   /write-desk-bill
          %arvo   %c  %info
          [dek %& [/desk/bill %ins %bill !>(~[dek])]~]
      ==
    ::  ;<  ~  bind:m  (take-poke-ack:io /write-desk-bill)
    %-  pure:m
    !>  ^-  json
    %-  pairs:enjs:format
    :~  ['type' s+'text']
        ['text' s+(crip "Added new desk {<dek>}")]
    ==
==
