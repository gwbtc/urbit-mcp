/+  *test, oa=mcp-oauth
|%
++  now  ~2026.1.1
++  uri  'http://localhost:4000/callback'
::
::  a client registered, consented to, and holding a code
++  coded
  ^-  [client=@t code=@t s=state:oa]
  =/  [client=@t s=state:oa]
    (need (register:oa *state:oa now 0v1 'test' ~[uri]))
  =^  id=@t  s
    %:  open-request:oa
        s
        now
        0v2
        client
        [uri (s256:oa 'verifier') `'xyz']
    ==
  =/  [url=@t s=state:oa]  (need (approve:oa s now 0v3 id))
  [client (~(got by (parse-query:oa url)) 'code') s]
::
::  the same client holding tokens
++  tokened
  ^-  [client=@t =tokens:oa s=state:oa]
  =/  [client=@t code=@t s=state:oa]  coded
  =^  got=(unit tokens:oa)  s
    (redeem:oa s now 0v4 client code `uri 'verifier')
  [client (need got) s]
::
::  the vector in rfc 7636 appendix b
++  test-s256
  %+  expect-eq
    !>('E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM')
  !>((s256:oa 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'))
::
::  eyre takes "Bearer 0v..." for one of its own sessions
++  test-mint
  =/  a=@t  (mint:oa %access 0v1)
  ;:  weld
    (expect-eq !>('mcp_') !>((end [3 4] a)))
    (expect-eq !>(47) !>((met 3 a)))
    (expect-eq !>(|) !>(=(a (mint:oa %refresh 0v1))))
    (expect-eq !>(|) !>(=(a (mint:oa %access 0v2))))
  ==
::
++  test-parse
  =/  form=(map @t @t)
    %-  parse-form:oa
    `(as-octs:mimes:html 'a=1&redirect_uri=http%3A%2F%2Fx%2Fy&c=d+e')
  ;:  weld
    (expect-eq !>(`'1') !>((~(get by form) 'a')))
    (expect-eq !>(`'http://x/y') !>((~(get by form) 'redirect_uri')))
    (expect-eq !>(`'d e') !>((~(get by form) 'c')))
    (expect-eq !>(~) !>((parse-form:oa ~)))
    (expect-eq !>(~) !>((parse-query:oa '/oauth/authorize')))
    %+  expect-eq
      !>(`'b')
    !>((~(get by (parse-query:oa '/oauth/authorize?a=b&c=d')) 'a'))
  ==
::
++  test-callback
  ;:  weld
    %+  expect-eq
      !>('http://x/cb?code=a%26b&state=s')
    !>((callback:oa 'http://x/cb' ~[['code' 'a&b'] ['state' 's']]))
    %+  expect-eq
      !>('http://x/cb?k=v&code=c')
    !>((callback:oa 'http://x/cb?k=v' ~[['code' 'c']]))
  ==
::
++  test-bearer
  ;:  weld
    (expect-eq !>(`'tok') !>((bearer:oa ~[['authorization' 'Bearer tok']])))
    (expect-eq !>(`'tok') !>((bearer:oa ~[['authorization' 'bearer tok']])))
    (expect-eq !>(~) !>((bearer:oa ~[['authorization' 'Basic tok']])))
    (expect-eq !>(~) !>((bearer:oa ~)))
  ==
::
::  loopback redirects match on any port; nothing else bends
++  test-same-redirect
  ;:  weld
    (expect-eq !>(&) !>((same-redirect:oa uri uri)))
    (expect-eq !>(&) !>((same-redirect:oa uri 'http://localhost:9/callback')))
    (expect-eq !>(&) !>((same-redirect:oa uri 'http://localhost/callback')))
    (expect-eq !>(|) !>((same-redirect:oa uri 'http://localhost:9/other')))
    (expect-eq !>(|) !>((same-redirect:oa uri 'http://127.0.0.1:4000/callback')))
    (expect-eq !>(|) !>((same-redirect:oa uri 'http://localhost.evil.com/callback')))
    (expect-eq !>(|) !>((same-redirect:oa uri 'http://localhost:9@evil.com/callback')))
    %+  expect-eq
      !>(|)
    !>((same-redirect:oa 'https://a.com:1/cb' 'https://a.com:2/cb'))
  ==
::
++  test-register
  =/  [id=@t s=state:oa]
    (need (register:oa *state:oa now 0v1 'test' ~[uri]))
  ;:  weld
    (expect-eq !>(&) !>((registered:oa s id uri)))
    (expect-eq !>(&) !>((registered:oa s id 'http://localhost:1/callback')))
    (expect-eq !>(|) !>((registered:oa s id 'https://evil.com/callback')))
    (expect-eq !>(|) !>((registered:oa s 'nobody' uri)))
    (expect-eq !>(~) !>((register:oa *state:oa now 0v1 'test' ~)))
    (expect-eq !>(~) !>((register:oa *state:oa now 0v1 'test' ~['a b'])))
    (expect-eq !>(~) !>((register:oa *state:oa now 0v1 'test' ~['http://x/#f'])))
    %+  expect-eq
      !>(~)
    !>((register:oa *state:oa now 0v1 'test' (reap 9 uri)))
  ==
::
::  a full table drops its stalest client and that client's grants
++  test-evict
  =/  [first=@t =tokens:oa s=state:oa]  tokened
  =/  n=@ud  1
  |-
  ?:  (lth n max-clients:oa)
    =/  [@t new=state:oa]
      (need (register:oa s (add now (mul n ~s1)) (add 0v10 n) 'more' ~[uri]))
    $(n +(n), s new)
  =/  [last=@t full=state:oa]
    (need (register:oa s (add now ~d1) 0v9 'last' ~[uri]))
  ;:  weld
    (expect-eq !>(max-clients:oa) !>(~(wyt by clients.s)))
    (expect-eq !>(&) !>((check:oa s now access.tokens)))
    (expect-eq !>(max-clients:oa) !>(~(wyt by clients.full)))
    (expect-eq !>(|) !>((~(has by clients.full) first)))
    (expect-eq !>(&) !>((~(has by clients.full) last)))
    (expect-eq !>(|) !>((check:oa full now access.tokens)))
  ==
::
++  test-approve
  =/  [client=@t s=state:oa]
    (need (register:oa *state:oa now 0v1 'test' ~[uri]))
  =^  id=@t  s
    (open-request:oa s now 0v2 client [uri 'chal' `'xyz'])
  =/  [url=@t done=state:oa]  (need (approve:oa s now 0v3 id))
  =/  args=(map @t @t)  (parse-query:oa url)
  ;:  weld
    (expect-eq !>(`'xyz') !>((~(get by args) 'state')))
    (expect-eq !>(&) !>((~(has by args) 'code')))
    ::  a request id works once, and only until it expires
    (expect-eq !>(~) !>((approve:oa done now 0v4 id)))
    (expect-eq !>(~) !>((approve:oa s (add now ~m11) 0v3 id)))
    (expect-eq !>(~) !>((approve:oa s now 0v3 'mcp_forged')))
    ::  a code is not a request id
    (expect-eq !>(~) !>((approve:oa done now 0v4 (~(got by args) 'code'))))
  ==
::
++  test-deny
  =/  [client=@t s=state:oa]
    (need (register:oa *state:oa now 0v1 'test' ~[uri]))
  =^  id=@t  s
    (open-request:oa s now 0v2 client [uri 'chal' ~])
  =/  [url=@t done=state:oa]  (need (deny:oa s now id))
  ;:  weld
    %+  expect-eq
      !>('http://localhost:4000/callback?error=access_denied')
    !>(url)
    (expect-eq !>(~) !>(grants.done))
  ==
::
++  test-redeem
  =/  [client=@t code=@t s=state:oa]  coded
  =/  good  (redeem:oa s now 0v4 client code `uri 'verifier')
  =/  spent=state:oa  +.good
  ;:  weld
    (expect-eq !>(&) !>(?=(^ -.good)))
    ::  the redirect is optional, but must match if sent
    (expect-eq !>(|) !>(=(~ -:(redeem:oa s now 0v4 client code ~ 'verifier'))))
    (expect-eq !>(~) !>(-:(redeem:oa s now 0v4 client code `'http://x' 'verifier')))
    (expect-eq !>(~) !>(-:(redeem:oa s now 0v4 client code `uri 'wrong')))
    (expect-eq !>(~) !>(-:(redeem:oa s now 0v4 'other' code `uri 'verifier')))
    (expect-eq !>(~) !>(-:(redeem:oa s (add now ~m6) 0v4 client code `uri 'verifier')))
    ::  a code is spent by its first use, right or wrong
    (expect-eq !>(~) !>(-:(redeem:oa spent now 0v5 client code `uri 'verifier')))
    %+  expect-eq
      !>(~)
    =/  burnt=state:oa  +:(redeem:oa s now 0v4 client code `uri 'wrong')
    !>(-:(redeem:oa burnt now 0v5 client code `uri 'verifier'))
  ==
::
++  test-check
  =/  [client=@t =tokens:oa s=state:oa]  tokened
  ;:  weld
    (expect-eq !>(&) !>((check:oa s now access.tokens)))
    (expect-eq !>(&) !>((check:oa s (add now ~m59) access.tokens)))
    (expect-eq !>(|) !>((check:oa s (add now ~h1) access.tokens)))
    ::  a refresh token is not an access token
    (expect-eq !>(|) !>((check:oa s now refresh.tokens)))
    (expect-eq !>(|) !>((check:oa s now 'mcp_forged')))
    (expect-eq !>(|) !>((check:oa *state:oa now access.tokens)))
    ::  state holds hashes, not the secrets
    (expect-eq !>(|) !>((~(has by grants.s) `@ux`access.tokens)))
    (expect-eq !>(&) !>((~(has by grants.s) (shax access.tokens))))
  ==
::
++  test-renew
  =/  [client=@t =tokens:oa s=state:oa]  tokened
  =/  later=@da  (add now ~d1)
  =^  got=(unit tokens:oa)  s
    (renew:oa s later 0v5 client refresh.tokens)
  =/  new=tokens:oa  (need got)
  ;:  weld
    (expect-eq !>(&) !>((check:oa s later access.new)))
    (expect-eq !>(|) !>(=(access.new access.tokens)))
    ::  the old refresh token died with its use
    (expect-eq !>(~) !>(-:(renew:oa s later 0v6 client refresh.tokens)))
    (expect-eq !>(|) !>(=(~ -:(renew:oa s later 0v6 client refresh.new))))
    (expect-eq !>(~) !>(-:(renew:oa s later 0v6 'other' refresh.new)))
    (expect-eq !>(~) !>(-:(renew:oa s later 0v6 client access.new)))
    (expect-eq !>(~) !>(-:(renew:oa s (add later ~d31) 0v6 client refresh.new)))
  ==
::
++  test-prune
  =/  [client=@t =tokens:oa s=state:oa]  tokened
  ;:  weld
    (expect-eq !>(2) !>(~(wyt by grants:(prune:oa s now))))
    (expect-eq !>(1) !>(~(wyt by grants:(prune:oa s (add now ~h2)))))
    (expect-eq !>(0) !>(~(wyt by grants:(prune:oa s (add now ~d31)))))
    (expect-eq !>(0) !>(~(wyt by grants:(drop:oa s client))))
  ==
--
