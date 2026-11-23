/-  mcp
^-  template:resource:mcp
:*  'scry://gx/mcp-proxy/server/{knot}/json'
    'mcp/mcp-server'
    `'Read a remote MCP server'
    `'Read one remote MCP server from %mcp-proxy. {knot} is the server id encoded with (scot %t id); mcp/mcp-servers lists each knot.'
    `'application/json'
    ~
    `[~['agent'] ~ ~]
==
