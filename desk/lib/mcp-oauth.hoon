::  pure state for the oauth 2.1 authorization server %mcp-server
::  runs for its own /mcp endpoint. eyre's login page checks +code;
::  this core registers clients, records consent, and mints and
::  checks tokens. state keeps the hash of every secret it mints,
::  never the secret itself.
|%
+$  client
  $:  name=@t
      redirects=(list @t)
      ::  time of last use; the stalest client is evicted first
      used=@da
  ==
::
::  what an authorization request asked for; .opaque is the
::  client's own state parameter, echoed back on the redirect
+$  auth  [redirect=@t challenge=@t opaque=(unit @t)]
::
+$  grant
  $:  client-id=@t
      expires=@da
      $=  kind
      $%  ::  awaiting the user's consent
          [%request auth]
          ::  consented; awaiting exchange for tokens
          [%code auth]
          [%access ~]
          [%refresh ~]
      ==
  ==
::
::  .grants is keyed by the sha-256 of the secret
+$  state  [clients=(map @t client) grants=(map @ux grant)]
::
+$  tokens  [access=@t refresh=@t]
::
++  max-clients    32
++  max-redirects  8
++  max-bytes      2.048
++  request-ttl    ~m10
++  code-ttl       ~m5
++  access-ttl     ~h1
++  refresh-ttl    ~d30
::
++  en-base64url
  |=  dat=octs
  ^-  @t
  (~(en base64:mimes:html | &) dat)
::
::  +s256: pkce code challenge for .verifier
++  s256
  |=  verifier=@t
  ^-  @t
  (en-base64url 32 (shax verifier))
::
::  +mint: a fresh secret. entropy is fixed within an event, so
::  secrets minted together need distinct tags. eyre reads a
::  "Bearer 0v..." header as one of its own sessions and rejects
::  those it does not know; the prefix keeps ours out of its way
++  mint
  |=  [tag=@tas eny=@uvJ]
  ^-  @t
  (cat 3 'mcp_' (en-base64url 32 (shas tag eny)))
::
++  parse-form
  |=  body=(unit octs)
  ^-  (map @t @t)
  ?~  body
    ~
  %-  ~(gas by *(map @t @t))
  (fall (rush q.u.body yquy:de-purl:html) ~)
::
++  parse-query
  |=  url=@t
  ^-  (map @t @t)
  =/  =tape  (trip url)
  =/  cut=(unit @ud)  (find "?" tape)
  ?~  cut
    ~
  (parse-form `(as-octt:mimes:html (slag +(u.cut) tape)))
::
++  en-query
  |=  args=(list [key=@t val=@t])
  ^-  tape
  ?~  args
    ~
  ;:  weld
    (en-urlt:html (trip key.i.args))
    "="
    (en-urlt:html (trip val.i.args))
    ?~(t.args ~ ['&' $(args t.args)])
  ==
::
::  +callback: .redirect with .args added to its query
++  callback
  |=  [redirect=@t args=(list [key=@t val=@t])]
  ^-  @t
  %-  crip
  ;:  weld
    (trip redirect)
    ?~((find "?" (trip redirect)) "?" "&")
    (en-query args)
  ==
::
::  +bearer: the token in an authorization header
++  bearer
  |=  headers=header-list:http
  ^-  (unit @t)
  =/  got=(unit @t)  (get-header:http 'authorization' headers)
  ?~  got
    ~
  =/  =tape  (trip u.got)
  ?.  =("bearer " (cass (scag 7 tape)))
    ~
  `(crip (slag 7 tape))
::
::  +valid-uri: a redirect uri is client input that ends up in a
::  location header and on the consent page
++  valid-uri
  |=  uri=@t
  ^-  ?
  ?&  !=('' uri)
      (lte (met 3 uri) max-bytes)
      (levy (trip uri) |=(c=@ &((gth c ' ') (lth c 0x7f) !=(c '#'))))
  ==
::
::  +portless: an http loopback uri with its port removed, or ~
::  for any other uri. native clients listen on a port they pick
::  at run time, so loopback redirects match on any port (rfc 8252)
++  portless
  |=  uri=@t
  ^-  (unit tape)
  =/  =tape  (trip uri)
  =/  hosts=(list ^tape)
    ~["http://localhost" "http://127.0.0.1" "http://[::1]"]
  |-
  ?~  hosts
    ~
  =/  len=@ud  (lent i.hosts)
  ?.  =(i.hosts (scag len tape))
    $(hosts t.hosts)
  =/  rest=^tape  (slag len tape)
  ?.  ?=([%':' *] rest)
    `tape
  =/  path=^tape  t.rest
  |-
  ?:  &(?=(^ path) (gte i.path '0') (lte i.path '9'))
    $(path t.path)
  `(weld i.hosts path)
::
++  same-redirect
  |=  [a=@t b=@t]
  ^-  ?
  ?:  =(a b)
    &
  =/  pa=(unit tape)  (portless a)
  &(?=(^ pa) =(pa (portless b)))
::
::  +registered: .redirect is one .client-id signed up with
++  registered
  |=  [s=state client-id=@t redirect=@t]
  ^-  ?
  =/  got=(unit client)  (~(get by clients.s) client-id)
  ?~  got
    |
  (lien redirects.u.got |=(r=@t (same-redirect r redirect)))
::
++  keep
  |=  [grants=(map @ux grant) ok=$-(grant ?)]
  ^+  grants
  %-  ~(gas by *(map @ux grant))
  (skim ~(tap by grants) |=([@ux g=grant] (ok g)))
::
::  +prune: forget expired grants
++  prune
  |=  [s=state now=@da]
  ^-  state
  s(grants (keep grants.s |=(g=grant (gth expires.g now))))
::
::  +drop: forget a client and everything issued to it
++  drop
  |=  [s=state id=@t]
  ^-  state
  %=  s
    clients  (~(del by clients.s) id)
    grants   (keep grants.s |=(g=grant !=(id client-id.g)))
  ==
::
::  +seek: the live grant .secret names
++  seek
  |=  [s=state now=@da secret=@t]
  ^-  (unit grant)
  =/  got=(unit grant)  (~(get by grants.s) (shax secret))
  ?~  got
    ~
  ?.  (gth expires.u.got now)
    ~
  got
::
::  +register: sign up a client. registration is open to anyone
::  who can reach the ship, so the table is bounded: a full table
::  drops its stalest client
++  register
  |=  [s=state now=@da eny=@uvJ name=@t redirects=(list @t)]
  ^-  (unit [id=@t state])
  ?.  ?&  ?=(^ redirects)
          (lte (lent redirects) max-redirects)
          (levy `(list @t)`redirects valid-uri)
          (lte (met 3 name) max-bytes)
      ==
    ~
  =/  stale=(list [id=@t client])
    %+  sort  ~(tap by clients.s)
    |=([a=[@t client] b=[@t client]] (lth used.a used.b))
  =?  s  &(?=(^ stale) (gte (lent stale) max-clients))
    (drop s id.i.stale)
  =/  id=@t  (mint %client eny)
  `[id s(clients (~(put by clients.s) id [name redirects now]))]
::
::  +open-request: record an authorization request to show the
::  user; the id it returns is the consent form's csrf token
++  open-request
  |=  [s=state now=@da eny=@uvJ client-id=@t =auth]
  ^-  [id=@t state]
  =/  id=@t  (mint %request eny)
  :-  id
  %=    s
      grants
    %+  ~(put by grants.s)  (shax id)
    [client-id (add now request-ttl) %request auth]
  ==
::
::  +approve: the user said yes; turn request .id into a code
::  and produce the url that carries it back to the client
++  approve
  |=  [s=state now=@da eny=@uvJ id=@t]
  ^-  (unit [url=@t state])
  =/  got=(unit grant)  (seek s now id)
  ?~  got
    ~
  ?.  ?=(%request -.kind.u.got)
    ~
  =/  code=@t  (mint %code eny)
  :-  ~
  :-  %+  callback  redirect.kind.u.got
      :-  ['code' code]
      ?~(opaque.kind.u.got ~ ['state' u.opaque.kind.u.got]~)
  %=    s
      grants
    %+  ~(put by (~(del by grants.s) (shax id)))  (shax code)
    [client-id.u.got (add now code-ttl) %code +.kind.u.got]
  ==
::
::  +deny: the user said no
++  deny
  |=  [s=state now=@da id=@t]
  ^-  (unit [url=@t state])
  =/  got=(unit grant)  (seek s now id)
  ?~  got
    ~
  ?.  ?=(%request -.kind.u.got)
    ~
  :-  ~
  :-  %+  callback  redirect.kind.u.got
      :-  ['error' 'access_denied']
      ?~(opaque.kind.u.got ~ ['state' u.opaque.kind.u.got]~)
  s(grants (~(del by grants.s) (shax id)))
::
++  issue
  |=  [s=state now=@da eny=@uvJ client-id=@t]
  ^-  [(unit tokens) state]
  ?.  (~(has by clients.s) client-id)
    [~ s]
  =/  access=@t   (mint %access eny)
  =/  refresh=@t  (mint %refresh eny)
  :-  `[access refresh]
  %=    s
      clients
    (~(jab by clients.s) client-id |=(c=client c(used now)))
  ::
      grants
    %-  ~(gas by grants.s)
    ^-  (list [@ux grant])
    :~  [(shax access) client-id (add now access-ttl) %access ~]
        [(shax refresh) client-id (add now refresh-ttl) %refresh ~]
    ==
  ==
::
::  +redeem: exchange a code for tokens. a code is spent by its
::  first use, right or wrong
++  redeem
  |=  $:  s=state
          now=@da
          eny=@uvJ
          client-id=@t
          code=@t
          redirect=(unit @t)
          verifier=@t
      ==
  ^-  [(unit tokens) state]
  =/  got=(unit grant)  (seek s now code)
  ?~  got
    [~ s]
  ?.  ?=(%code -.kind.u.got)
    [~ s]
  =.  grants.s  (~(del by grants.s) (shax code))
  ?.  ?&  =(client-id client-id.u.got)
          |(?=(~ redirect) =(u.redirect redirect.kind.u.got))
          =(challenge.kind.u.got (s256 verifier))
      ==
    [~ s]
  (issue s now eny client-id)
::
::  +renew: exchange a refresh token for a new pair; the old
::  refresh token dies
++  renew
  |=  [s=state now=@da eny=@uvJ client-id=@t token=@t]
  ^-  [(unit tokens) state]
  =/  got=(unit grant)  (seek s now token)
  ?~  got
    [~ s]
  ?.  &(?=(%refresh -.kind.u.got) =(client-id client-id.u.got))
    [~ s]
  (issue s(grants (~(del by grants.s) (shax token))) now eny client-id)
::
::  +check: .token is a live access token
++  check
  |=  [s=state now=@da token=@t]
  ^-  ?
  =/  got=(unit grant)  (seek s now token)
  ?~  got
    |
  ?=(%access -.kind.u.got)
::
::  +resource-meta: rfc 9728 protected-resource metadata
++  resource-meta
  |=  base=@t
  ^-  json
  %-  pairs:enjs:format
  :~  ['resource' s+(cat 3 base '/mcp')]
      ['authorization_servers' a+~[s+base]]
      ['bearer_methods_supported' a+~[s+'header']]
  ==
::
::  +server-meta: rfc 8414 authorization-server metadata
++  server-meta
  |=  base=@t
  ^-  json
  %-  pairs:enjs:format
  :~  ['issuer' s+base]
      ['authorization_endpoint' s+(cat 3 base '/oauth/authorize')]
      ['token_endpoint' s+(cat 3 base '/oauth/token')]
      ['registration_endpoint' s+(cat 3 base '/oauth/register')]
      ['response_types_supported' a+~[s+'code']]
      :-  'grant_types_supported'
      a+~[s+'authorization_code' s+'refresh_token']
      ['code_challenge_methods_supported' a+~[s+'S256']]
      ['token_endpoint_auth_methods_supported' a+~[s+'none']]
  ==
::
::  +styling: the look of eyre's login page, which the user has
::  just come from; copied from +auth-styling in eyre, less the
::  rules for parts these pages lack
++  styling
  '''
  @import url("https://rsms.me/inter/inter.css");
  @font-face {
      font-family: "Source Code Pro";
      src: url("https://storage.googleapis.com/media.urbit.org/fonts/scp-regular.woff");
      font-weight: 400;
      font-display: swap;
  }
  :root {
    --gray-100: #E5E5E5;
    --gray-400: #999999;
    --gray-800: #333333;
    --white: #FFFFFF;
  }
  html {
    font-family: Inter, sans-serif;
    height: 100%;
    margin: 0;
    width: 100%;
    background: var(--white);
    color: var(--gray-800);
    -webkit-font-smoothing: antialiased;
    line-height: 1.5;
    font-size: 16px;
    font-weight: 600;
    display: flex;
    flex-flow: row nowrap;
    justify-content: center;
  }
  body {
    display: flex;
    flex-flow: column nowrap;
    justify-content: center;
    max-width: 300px;
    padding: 1rem;
    width: 100%;
  }
  input {
    background: var(--gray-100);
    border: 2px solid transparent;
    padding: 0.5rem;
    border-radius: 0.5rem;
    font-size: inherit;
    color: var(--gray-800);
    box-shadow: none;
    width: 100%;
    box-sizing: border-box;
  }
  input:disabled {
    background: var(--gray-100);
    color: var(--gray-400);
  }
  p.note {
    color: var(--gray-400);
    font-weight: 400;
    overflow-wrap: anywhere;
  }
  form {
    display: flex;
    flex-flow: row nowrap;
    gap: 0.5rem;
    margin-top: 1rem;
  }
  button[type=submit] {
    font-size: 1rem;
    padding: 0.5rem 1rem;
    border-radius: 0.5rem;
    background: var(--gray-800);
    color: var(--white);
    border: none;
    font-weight: 600;
    cursor: pointer;
  }
  button[type=submit].deny {
    background: var(--gray-100);
    color: var(--gray-800);
  }
  .mono {
    font-family: 'Source Code Pro', monospace;
  }
  @media all and (prefers-color-scheme: dark) {
  :root {
    --white: #000000;
    --gray-800: #E5E5E5;
    --gray-400: #808080;
    --gray-100: #333333;
  }
  }
  @media screen and (min-width: 30em) {
    html {
      font-size: 14px;
    }
  }
  '''
::
++  page
  |=  body=marl
  ^-  octs
  %-  as-octt:mimes:html
  %+  weld  "<!DOCTYPE html>"
  %-  en-xml:html
  ;html
    ;head
      ;meta(charset "utf-8");
      ;meta(name "viewport", content "width=device-width, initial-scale=1, shrink-to-fit=no");
      ;title:"Urbit"
      ;style:"{(trip styling)}"
    ==
    ;body
      ;*  body
    ==
  ==
::
++  error-page
  |=  msg=tape
  ^-  octs
  %-  page
  ;=  ;p:"Cannot authorize"
      ;p.note:"{msg}"
  ==
::
::  +consent-page: ask the user to let a client in. .id goes back
::  in the form; a page on another origin cannot read it
++  consent-page
  |=  [our=@p name=@t id=@t]
  ^-  octs
  %-  page
  ;=  ;p:"Urbit ID"
      ;input(value "{(scow %p our)}", disabled "true", class "mono");
      ;p:"MCP client"
      ;input(value "{?:(=('' name) "unnamed" (trip name))}", disabled "true");
      ;p.note:"Allowing access lets this MCP client do anything you can do from this ship's Dojo."
      ;form(method "post", action "/oauth/authorize")
        ;input(type "hidden", name "request", value "{(trip id)}");
        ;button(type "submit", name "choice", value "allow"):"Allow"
        ;button.deny(type "submit", name "choice", value "deny"):"Deny"
      ==
  ==
--
