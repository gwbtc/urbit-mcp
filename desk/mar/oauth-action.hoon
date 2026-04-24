::  oauth-action: mark for oauth agent actions
::
/-  oauth
|_  act=action:oauth
++  grow
  |%
  ++  noun  act
  --
++  grab
  |%
  ++  noun  action:oauth
  ++  json
    |=  jon=^json
    ^-  action:oauth
    =,  dejs:format
    =/  typ=@t  ((ot ~[action+so]) jon)
    ?+  typ  !!
        %'add-provider'
      =/  f
        %-  ot
        :~  id+so
            auth-url+so
            token-url+so
            revoke-url+(mu so)
            client-id+so
            client-secret+so
            redirect-uri+so
            scopes+so
        ==
      =/  $:  id=@t
              auth-url=@t
              token-url=@t
              revoke-url=(unit @t)
              client-id=@t
              client-secret=@t
              redirect-uri=@t
              scopes=@t
          ==
        (f jon)
      [%add-provider `@tas`id [auth-url token-url revoke-url client-id client-secret redirect-uri scopes]]
    ::
        %'remove-provider'
      [%remove-provider `@tas`((ot ~[id+so]) jon)]
    ::
        %'update-provider'
      =/  f
        %-  ot
        :~  id+so
            auth-url+so
            token-url+so
            revoke-url+(mu so)
            client-id+so
            client-secret+so
            redirect-uri+so
            scopes+so
        ==
      =/  $:  id=@t
              auth-url=@t
              token-url=@t
              revoke-url=(unit @t)
              client-id=@t
              client-secret=@t
              redirect-uri=@t
              scopes=@t
          ==
        (f jon)
      [%update-provider `@tas`id [auth-url token-url revoke-url client-id client-secret redirect-uri scopes]]
    ::
        %'connect'
      [%connect `@tas`((ot ~[id+so]) jon)]
    ::
        %'disconnect'
      [%disconnect `@tas`((ot ~[id+so]) jon)]
    ::
        %'revoke'
      [%revoke `@tas`((ot ~[id+so]) jon)]
    ==
  --
++  grad  %noun
--
