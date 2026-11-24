/-  mcp
^-  template:resource:mcp
:*  'scry://gx/mcp-proxy/server/{knot}/json'
    'mcp/remote-mcp-server'
    `'Read a remote MCP server'
    `'Read one remote MCP server from %mcp-proxy. {knot} is the server id encoded with (scot %t id); mcp/remote-mcp-servers lists each knot.'
    `'application/json'
    ~
    `[~['agent'] ~ ~]
==
