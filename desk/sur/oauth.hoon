::  oauth: types for OAuth 2.0 + PKCE agent
::
|%
+$  provider-id  @tas
::
::  $provider-config: OAuth provider endpoint configuration
::
::  .auth-url: authorization endpoint
::  .token-url: token exchange endpoint
::  .revoke-url: optional revocation endpoint
::  .client-id: OAuth client identifier
::  .client-secret: OAuth client secret
::  .redirect-uri: callback URL on this ship
::  .scopes: space-separated scope string
::
+$  provider-config
  $:  auth-url=@t
      token-url=@t
      revoke-url=(unit @t)
      client-id=@t
      client-secret=@t
      redirect-uri=@t
      scopes=@t
  ==
::
::  $grant: stored OAuth token set
::
::  .access-token: bearer token
::  .refresh-token: optional refresh token
::  .token-type: e.g. "Bearer"
::  .expires-at: absolute expiry time (or ~)
::  .scopes: granted scopes
::  .provider-id: which provider this grant is for
::
+$  grant
  $:  access-token=@t
      refresh-token=(unit @t)
      token-type=@t
      expires-at=(unit @da)
      scopes=@t
      =provider-id
  ==
::
::  $pending-auth: in-flight OAuth authorization
::
::  .state: random state parameter (lookup key)
::  .verifier: PKCE code verifier
::  .provider-id: which provider
::
+$  pending-auth
  $:  state=@t
      verifier=@t
      =provider-id
  ==
::
+$  state-0
  $:  %0
      providers=(map provider-id provider-config)
      grants=(map provider-id grant)
      pending=(map @t pending-auth)
  ==
::
+$  versioned-state
  $%  state-0
  ==
::
+$  action
  $%  [%add-provider id=provider-id config=provider-config]
      [%remove-provider id=provider-id]
      [%update-provider id=provider-id config=provider-config]
      [%connect id=provider-id]
      [%disconnect id=provider-id]
      [%revoke id=provider-id]
      [%force-refresh id=provider-id]
  ==
::
+$  update
  $%  [%grant-added =provider-id =grant]
      [%grant-removed =provider-id]
      [%grant-refreshed =provider-id =grant]
      [%token-expired =provider-id]
  ==
--
