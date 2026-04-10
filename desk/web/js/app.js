var App = {
  servers: [],
  oauthProviders: [],
  editing: null,
  editingProvider: null,
  openTools: null,
  ship: '',
  activeSection: 'endpoint',

  init: function() {
    this.bindEvents();
    this.initSectionFromHash();
    this.loadAll();
  },

  initSectionFromHash: function() {
    var hash = (window.location.hash || '').replace('#', '');
    if (hash === 'upstreams' || hash === 'oauth' || hash === 'endpoint') {
      this.activateSection(hash);
    }
  },

  activateSection: function(name) {
    this.activeSection = name;
    var tabs = document.querySelectorAll('.section-tab');
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].classList.toggle('is-active', tabs[i].getAttribute('data-section') === name);
    }
    var panes = document.querySelectorAll('.section-pane');
    for (var j = 0; j < panes.length; j++) {
      panes[j].classList.toggle('is-active', panes[j].getAttribute('data-pane') === name);
    }
    if (window.history && window.history.replaceState) {
      try { window.history.replaceState(null, '', '#' + name); } catch (e) {}
    }
  },

  loadAll: function() {
    var self = this;
    Promise.all([
      McpProxyAPI.getServers(),
      OAuthAPI.getProviders().catch(function() { return { providers: [] }; }),
      McpProxyAPI.getClientKey().catch(function() { return {}; })
    ]).then(function(results) {
      self.ship = results[0].ship || '';
      self.servers = results[0].servers || [];
      self.oauthProviders = results[1].providers || [];
      self.clientKey = results[2].clientKey || null;
      self.updateEndpoint();
      self.updateStats();
      self.render();
      self.renderOAuth();
      self.populateOAuthSelects();
    }).catch(function(e) {
      console.error(e);
    });
  },

  updateEndpoint: function() {
    var url = window.location.origin + '/apps/mcp/mcp';
    var urlEl = document.getElementById('agg-url');
    var keyEl = document.getElementById('agg-key');
    var exampleEl = document.getElementById('endpoint-example');
    var hasKey = !!this.clientKey;
    var key = this.clientKey || '';

    if (urlEl) urlEl.textContent = url;
    if (keyEl) {
      keyEl.textContent = hasKey ? key : '— not set —';
      keyEl.classList.toggle('is-unset', !hasKey);
    }
    if (exampleEl) {
      var name = (this.ship || 'mcp').replace(/^~/, '') || 'mcp';
      if (hasKey) {
        exampleEl.textContent =
          'claude mcp add --transport http ' + name + ' \\\n  ' + url +
          ' \\\n  --header "X-Api-Key: ' + key + '"';
      } else {
        exampleEl.textContent =
          '# set an api key below, then run:\n' +
          'claude mcp add --transport http ' + name + ' \\\n  ' + url +
          ' \\\n  --header "X-Api-Key: <your-key>"';
      }
    }
  },

  updateStats: function() {
    var shipEl = document.getElementById('stat-ship');
    var upEl = document.getElementById('stat-upstreams');
    var oaEl = document.getElementById('stat-oauth');
    var footShip = document.getElementById('foot-ship');
    var tabUp = document.getElementById('tab-count-upstreams');
    var tabOa = document.getElementById('tab-count-oauth');

    var enabled = 0;
    for (var i = 0; i < this.servers.length; i++) if (this.servers[i].enabled) enabled++;
    var connected = 0;
    for (var j = 0; j < this.oauthProviders.length; j++) if (this.oauthProviders[j].hasGrant) connected++;

    var shipDisplay = this.ship || '—';
    if (shipEl)  shipEl.textContent  = shipDisplay;
    if (footShip) footShip.textContent = shipDisplay;
    if (upEl)    upEl.textContent    = enabled + ' / ' + this.servers.length + ' active';
    if (oaEl)    oaEl.textContent    = connected + ' / ' + this.oauthProviders.length + ' linked';
    if (tabUp)   tabUp.textContent   = this.servers.length;
    if (tabOa)   tabOa.textContent   = this.oauthProviders.length;
  },

  populateOAuthSelects: function() {
    var selects = document.querySelectorAll('.oauth-select');
    for (var i = 0; i < selects.length; i++) {
      var sel = selects[i];
      var val = sel.dataset.currentValue || sel.value;
      sel.innerHTML = '<option value="">— none —</option>';
      for (var j = 0; j < this.oauthProviders.length; j++) {
        var p = this.oauthProviders[j];
        var opt = document.createElement('option');
        opt.value = p.id;
        opt.textContent = p.id + (p.hasGrant ? ' · connected' : '');
        sel.appendChild(opt);
      }
      if (val) sel.value = val;
    }
  },

  bindEvents: function() {
    var self = this;

    document.getElementById('add-form').addEventListener('submit', function(e) {
      e.preventDefault();
      var form = e.target;
      var id = form.elements.id.value.trim().toLowerCase().replace(/[^a-z0-9-]/g, '').replace(/^-+/, '').replace(/-+$/, '');
      var name = form.elements.name.value.trim();
      var url = form.elements.url.value.trim();
      var headers = self.getHeadersFromForm('add');
      var mode = form.elements.mode.value;
      var oauthProv = form.elements['oauth-provider'].value || null;
      var schemaUrl = form.elements['schema-url'] ? form.elements['schema-url'].value.trim() : '';
      if (!id || !name || (mode !== 'openapi' && !url)) return;
      McpProxyAPI.addServer(id, name, url, headers, {mode: mode, oauthProvider: oauthProv, schemaUrl: schemaUrl || null}).then(function() {
        form.reset();
        document.getElementById('add-schema-row').style.display = 'none';
        var rows = document.querySelectorAll('#add-headers .header-row');
        for (var i = 0; i < rows.length; i++) rows[i].remove();
        var drawer = form.closest('details');
        if (drawer) drawer.open = false;
        self.loadAll();
        self.toast('Upstream committed');
      }).catch(function(e) { alert('Failed: ' + e.message); });
    });

    document.getElementById('oauth-add-form').addEventListener('submit', function(e) {
      e.preventDefault();
      var f = e.target;
      var data = {
        action: 'add-provider',
        id: f.elements['id'].value.trim().toLowerCase(),
        'auth-url': f.elements['auth-url'].value.trim(),
        'token-url': f.elements['token-url'].value.trim(),
        'revoke-url': f.elements['revoke-url'].value.trim() || null,
        'client-id': f.elements['client-id'].value.trim(),
        'client-secret': f.elements['client-secret'].value.trim(),
        'redirect-uri': f.elements['redirect-uri'].value.trim(),
        scopes: f.elements['scopes'].value.trim()
      };
      OAuthAPI.addProvider(data).then(function() {
        f.reset();
        var drawer = f.closest('details');
        if (drawer) drawer.open = false;
        self.loadAll();
        self.toast('Provider committed');
      }).catch(function(e) { alert('Failed: ' + e.message); });
    });

    // delegated clicks: section tabs + copy buttons
    document.body.addEventListener('click', function(e) {
      var sectionTab = e.target.closest('.section-tab');
      if (sectionTab) {
        self.activateSection(sectionTab.getAttribute('data-section'));
        return;
      }

      var btn = e.target.closest('.copy-btn');
      if (!btn) return;
      var targetId = btn.getAttribute('data-copy');
      if (!targetId) return;
      var el = document.getElementById(targetId);
      if (!el) return;
      var text = el.textContent;
      if (navigator.clipboard) {
        navigator.clipboard.writeText(text).then(function() {
          btn.classList.add('copied');
          var label = btn.querySelector('.copy-btn-label');
          var prev = label ? label.textContent : null;
          if (label) label.textContent = 'OK';
          setTimeout(function() {
            btn.classList.remove('copied');
            if (label && prev !== null) label.textContent = prev;
          }, 1200);
        });
      }
    });

    window.addEventListener('hashchange', function() {
      self.initSectionFromHash();
    });

    // api-key management buttons
    var regenBtn = document.getElementById('btn-regen-key');
    if (regenBtn) regenBtn.addEventListener('click', function() {
      McpProxyAPI.regenerateClientKey().then(function() {
        self.loadAll();
        self.toast('API key generated');
      }).catch(function(e) { alert('Failed: ' + e.message); });
    });

    var setBtn = document.getElementById('btn-set-key');
    if (setBtn) setBtn.addEventListener('click', function() {
      var key = prompt('Enter a custom API key:');
      if (!key) return;
      key = key.trim();
      if (!key) return;
      McpProxyAPI.setClientKey(key).then(function() {
        self.loadAll();
        self.toast('API key set');
      }).catch(function(e) { alert('Failed: ' + e.message); });
    });

    var clearBtn = document.getElementById('btn-clear-key');
    if (clearBtn) clearBtn.addEventListener('click', function() {
      if (!confirm('Clear the API key? The proxy endpoint will stop serving until you set a new one.')) return;
      McpProxyAPI.clearClientKey().then(function() {
        self.loadAll();
        self.toast('API key cleared');
      }).catch(function(e) { alert('Failed: ' + e.message); });
    });
  },

  getHeadersFromForm: function(prefix) {
    var container = document.getElementById(prefix + '-headers');
    if (!container) return [];
    var rows = container.querySelectorAll('.header-row');
    var headers = [];
    for (var i = 0; i < rows.length; i++) {
      var key = rows[i].querySelector('.header-key').value.trim();
      var value = rows[i].querySelector('.header-value').value.trim();
      if (key && value) headers.push({ key: key, value: value });
    }
    return headers;
  },

  addHeaderRow: function(container, key, value) {
    var row = document.createElement('div');
    row.className = 'header-row';
    var k = document.createElement('input');
    k.type = 'text'; k.className = 'header-key'; k.placeholder = 'header-name'; k.value = key || '';
    var v = document.createElement('input');
    v.type = 'text'; v.className = 'header-value'; v.placeholder = 'value'; v.value = value || '';
    var btn = document.createElement('button');
    btn.type = 'button'; btn.className = 'icon-btn'; btn.innerHTML = '&times;';
    btn.setAttribute('aria-label', 'Remove header');
    btn.addEventListener('click', function() { row.remove(); });
    row.appendChild(k); row.appendChild(v); row.appendChild(btn);
    container.appendChild(row);
  },

  toggleSchemaUrl: function(prefix) {
    var mode = document.getElementById(prefix + '-mode').value;
    var row = document.getElementById(prefix + '-schema-row');
    var hint = document.getElementById(prefix + '-url-hint');
    var urlInput = document.getElementById(prefix + '-url');
    if (row) row.style.display = mode === 'openapi' ? '' : 'none';
    if (hint) hint.textContent = mode === 'openapi'
      ? 'API base URL · optional, derived from spec if empty'
      : 'Upstream MCP server endpoint';
    if (urlInput) urlInput.required = mode !== 'openapi';
  },

  editServer: function(id) {
    this.editing = id;
    this.openTools = null;
    this.render();
    this.populateOAuthSelects();
  },

  cancelEdit: function() { this.editing = null; this.render(); },

  saveServer: function(id) {
    var self = this;
    var card = document.getElementById('edit-' + id);
    var name = card.querySelector('.edit-name').value.trim();
    var url = card.querySelector('.edit-url').value.trim();
    var headers = this.getHeadersFromForm('edit-h-' + id);
    var oauthProv = card.querySelector('.edit-oauth').value || null;
    var mode = card.querySelector('.edit-mode').value;
    var schemaInput = card.querySelector('.edit-schema-url');
    var schemaUrl = schemaInput ? schemaInput.value.trim() : '';
    var s = this.servers.find(function(x) { return x.id === id; });
    if (!name || (mode !== 'openapi' && !url)) return;
    McpProxyAPI.updateServer(id, name, url, headers, s ? s.enabled : true, {
      mode: mode, oauthProvider: oauthProv, schemaUrl: schemaUrl || null
    }).then(function() {
      self.editing = null;
      self.loadAll();
      self.toast('Upstream updated');
    }).catch(function(e) { alert('Failed: ' + e.message); });
  },

  refreshSpec: function(id) {
    var self = this;
    McpProxyAPI.refreshSpec(id).then(function() {
      self.toast('Fetching schema…');
      setTimeout(function() { self.loadAll(); }, 3000);
    }).catch(function(e) { alert('Failed: ' + e.message); });
  },

  showTools: function(id) {
    var self = this;
    this.openTools = id;
    McpProxyAPI.getTools(id).then(function(data) {
      var tools = data.tools || [];
      var s = self.servers.find(function(x) { return x.id === id; });
      var filter = s && s.toolFilter ? s.toolFilter : null;
      var blockedSet = new Set(filter && filter.mode === 'block' ? filter.tools : []);
      var allowedSet = new Set(filter && filter.mode === 'allow' ? filter.tools : []);
      var isAllowMode = filter && filter.mode === 'allow';

      var active = 0;
      for (var k = 0; k < tools.length; k++) {
        var blocked = isAllowMode ? !allowedSet.has(tools[k].name) : blockedSet.has(tools[k].name);
        if (!blocked) active++;
      }

      var html = '<div class="tool-panel" id="tools-' + id + '">';
      html += '<div class="tool-panel-head">';
      html += '<div class="tool-count"><strong>' + active + '</strong> / ' + tools.length + ' tools active';
      if (filter) html += ' · ' + filter.mode + ' filter';
      html += '</div>';
      html += '<div class="tool-actions">' +
        '<button type="button" class="row-btn" onclick="App.setAllTools(\'' + id + '\',true)">All</button>' +
        '<button type="button" class="row-btn" onclick="App.setAllTools(\'' + id + '\',false)">None</button>' +
        '<button type="button" class="row-btn" onclick="App.hideTools(\'' + id + '\')">Close</button>' +
        '</div></div>';

      html += '<div class="tool-list">';
      if (tools.length === 0) {
        html += '<div class="empty">No tools discovered<em>check schema or connection</em></div>';
      } else {
        for (var i = 0; i < tools.length; i++) {
          var t = tools[i];
          var isBlocked = isAllowMode ? !allowedSet.has(t.name) : blockedSet.has(t.name);
          html += '<label class="tool-row ' + (isBlocked ? 'blocked' : '') + '">' +
            '<input type="checkbox" class="tool-checkbox" ' + (isBlocked ? '' : 'checked') +
            ' onchange="App.toggleTool(\'' + id + '\',\'' + self.esc(t.name) + '\',this.checked)">' +
            '<div class="tool-row-body">' +
              '<div class="tool-row-name">' + self.esc(t.name) + '</div>' +
              (t.description ? '<div class="tool-row-desc">' + self.esc(t.description) + '</div>' : '') +
            '</div>' +
            '</label>';
        }
      }
      html += '</div></div>';

      var container = document.getElementById('server-tools-' + id);
      if (container) container.innerHTML = html;
    }).catch(function(e) { alert('Failed to load tools: ' + e.message); });
  },

  setAllTools: function(id, enabled) {
    var self = this;
    if (enabled) {
      McpProxyAPI.clearToolFilter(id).then(function() {
        self.loadAll();
        self.showTools(id);
      });
    } else {
      McpProxyAPI.getTools(id).then(function(data) {
        var tools = (data.tools || []).map(function(t) { return t.name; });
        McpProxyAPI.setToolFilter(id, 'block', tools).then(function() {
          self.loadAll();
          self.showTools(id);
        });
      });
    }
  },

  hideTools: function(id) {
    this.openTools = null;
    var container = document.getElementById('server-tools-' + id);
    if (container) container.innerHTML = '';
  },

  toggleTool: function(serverId, toolName, enabled) {
    var self = this;
    var s = this.servers.find(function(x) { return x.id === serverId; });
    var filter = s && s.toolFilter ? s.toolFilter : { mode: 'block', tools: [] };
    var toolSet = new Set(filter.tools || []);

    if (filter.mode === 'block') {
      if (enabled) toolSet.delete(toolName); else toolSet.add(toolName);
    } else {
      if (enabled) toolSet.add(toolName); else toolSet.delete(toolName);
    }

    var tools = Array.from(toolSet);
    var done = function() { self.loadAll(); self.showTools(serverId); };
    if (tools.length === 0) {
      McpProxyAPI.clearToolFilter(serverId).then(done);
    } else {
      McpProxyAPI.setToolFilter(serverId, filter.mode, tools).then(done);
    }
  },

  toggleServer: function(id) {
    var self = this;
    McpProxyAPI.toggleServer(id).then(function() { self.loadAll(); })
      .catch(function(e) { alert('Failed: ' + e.message); });
  },

  removeServer: function(id) {
    var self = this;
    if (!confirm('Remove upstream "' + id + '"?')) return;
    McpProxyAPI.removeServer(id).then(function() {
      self.loadAll();
      self.toast('Upstream removed');
    }).catch(function(e) { alert('Failed: ' + e.message); });
  },

  editProvider: function(id) {
    this.editingProvider = id;
    this.renderOAuth();
  },

  cancelProviderEdit: function() {
    this.editingProvider = null;
    this.renderOAuth();
  },

  saveProvider: function(id) {
    var self = this;
    var card = document.getElementById('edit-provider-' + id);
    if (!card) return;
    var secretInput = card.querySelector('.edit-p-secret');
    var data = {
      action: 'update-provider',
      id: id,
      'auth-url': card.querySelector('.edit-p-auth-url').value.trim(),
      'token-url': card.querySelector('.edit-p-token-url').value.trim(),
      'revoke-url': card.querySelector('.edit-p-revoke-url').value.trim() || null,
      'client-id': card.querySelector('.edit-p-client-id').value.trim(),
      'client-secret': secretInput.value, // empty = preserve on backend
      'redirect-uri': card.querySelector('.edit-p-redirect').value.trim(),
      scopes: card.querySelector('.edit-p-scopes').value.trim()
    };
    OAuthAPI.updateProvider(data).then(function() {
      self.editingProvider = null;
      self.loadAll();
      self.toast('Provider updated');
    }).catch(function(e) { alert('Failed: ' + e.message); });
  },

  connectProvider: function(id) {
    var self = this;
    OAuthAPI.connect(id).then(function(data) {
      if (data && data.url) {
        window.open(data.url, '_blank');
        self.toast('Authorize in new tab, then reload');
      }
    }).catch(function(e) { alert('Connect failed: ' + e.message); });
  },

  disconnectProvider: function(id) {
    var self = this;
    OAuthAPI.disconnect(id).then(function() {
      self.loadAll();
      self.toast('Disconnected');
    }).catch(function(e) { alert('Failed: ' + e.message); });
  },

  removeProvider: function(id) {
    var self = this;
    if (!confirm('Remove provider "' + id + '"?')) return;
    OAuthAPI.removeProvider(id).then(function() {
      self.loadAll();
      self.toast('Provider removed');
    }).catch(function(e) { alert('Failed: ' + e.message); });
  },

  copyUrl: function(text) {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text);
      this.toast('Copied');
    }
  },

  toast: function(msg) {
    var el = document.getElementById('toast');
    if (!el) {
      el = document.createElement('div');
      el.id = 'toast';
      el.className = 'toast';
      document.body.appendChild(el);
    }
    el.textContent = msg;
    el.classList.add('show');
    clearTimeout(this._toastTimer);
    this._toastTimer = setTimeout(function() { el.classList.remove('show'); }, 2200);
  },

  renderEditCard: function(s) {
    var isOpenapi = s.mode === 'openapi';
    var headersHtml = '<div class="header-list" id="edit-h-' + s.id + '-headers">';
    if (s.headers) {
      for (var j = 0; j < s.headers.length; j++) {
        var h = s.headers[j];
        headersHtml += '<div class="header-row">' +
          '<input type="text" class="header-key" value="' + this.esc(h.key) + '">' +
          '<input type="text" class="header-value" value="' + this.esc(h.value) + '">' +
          '<button type="button" class="icon-btn" onclick="this.parentElement.remove()" aria-label="Remove">&times;</button>' +
        '</div>';
      }
    }
    headersHtml += '</div>';

    var oauthAttr = ' data-current-value="' + this.esc(s.oauthProvider || '') + '"';

    return '' +
    '<div class="server-card editing" id="edit-' + s.id + '">' +
      '<div class="card-row">' +
        '<div class="card-identity">' +
          '<div class="card-name">Editing · ' + this.esc(s.name) + '</div>' +
          '<div class="card-id">' + this.esc(s.id) + '</div>' +
        '</div>' +
      '</div>' +
      '<div class="edit-form">' +
        '<div class="form-grid">' +
          '<label class="field"><span class="field-label">NAME</span>' +
            '<input type="text" class="edit-name" value="' + this.esc(s.name) + '"></label>' +
          '<label class="field"><span class="field-label">MODE</span>' +
            '<select class="edit-mode" id="edit-' + s.id + '-mode" onchange="App.toggleSchemaUrl(\'edit-' + s.id + '\')">' +
              '<option value="proxy"' + (isOpenapi ? '' : ' selected') + '>Proxy — MCP Server</option>' +
              '<option value="openapi"' + (isOpenapi ? ' selected' : '') + '>OpenAPI — REST API</option>' +
            '</select></label>' +
        '</div>' +
        '<div class="form-grid">' +
          '<label class="field"><span class="field-label">URL</span>' +
            '<input type="url" class="edit-url" id="edit-' + s.id + '-url" value="' + this.esc(s.url || '') + '"' + (isOpenapi ? '' : ' required') + '></label>' +
          '<label class="field"><span class="field-label">OAUTH PROVIDER</span>' +
            '<select class="edit-oauth oauth-select"' + oauthAttr + '><option value="">— none —</option></select></label>' +
        '</div>' +
        '<label class="field field-full" id="edit-' + s.id + '-schema-row" style="' + (isOpenapi ? '' : 'display:none') + '">' +
          '<span class="field-label">SCHEMA URL</span>' +
          '<input type="url" class="edit-schema-url" value="' + this.esc(s.schemaUrl || '') + '">' +
        '</label>' +
        '<div class="form-section">' +
          '<div class="form-section-label">CUSTOM HEADERS</div>' +
          headersHtml +
          '<button type="button" class="ghost-btn" onclick="App.addHeaderRow(document.getElementById(\'edit-h-' + s.id + '-headers\'))">+ Add header</button>' +
        '</div>' +
        '<div class="form-actions">' +
          '<button type="button" class="row-btn" onclick="App.cancelEdit()">Cancel</button>' +
          '<button type="button" class="primary-btn" onclick="App.saveServer(\'' + s.id + '\')">Save changes</button>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  render: function() {
    var container = document.getElementById('servers');
    if (this.servers.length === 0) {
      container.innerHTML =
        '<div class="empty">NO UPSTREAMS CONFIGURED' +
        '<em>add your first MCP server or OpenAPI endpoint above</em></div>';
      return;
    }

    var html = '';
    for (var i = 0; i < this.servers.length; i++) {
      var s = this.servers[i];
      if (this.editing === s.id) { html += this.renderEditCard(s); continue; }

      var isOpenapi = s.mode === 'openapi';
      var isBuiltIn = this.ship && s.id === this.ship.replace(/^~/, '');
      var cardClass = 'server-card' + (s.enabled ? '' : ' disabled') + (isBuiltIn ? ' built-in' : '');

      // badges
      var badges = '';
      if (isBuiltIn) badges += '<span class="badge built-in">built-in</span>';
      badges += '<span class="badge mode-' + (isOpenapi ? 'openapi' : 'proxy') + '">' + (isOpenapi ? 'openapi' : 'proxy') + '</span>';
      badges += '<span class="badge ' + (s.enabled ? 'enabled' : 'disabled') + '">' + (s.enabled ? 'enabled' : 'disabled') + '</span>';

      // meta rows
      var meta = '';
      if (s.url) {
        meta += '<div class="meta-row"><div class="meta-key">URL</div><div class="meta-val accent">' + this.esc(s.url) + '</div></div>';
      }
      if (isOpenapi && s.schemaUrl) {
        var specBadge = s.hasCachedSpec
          ? '<span class="badge cached">cached</span>'
          : '<span class="badge stale">not cached</span>';
        meta += '<div class="meta-row"><div class="meta-key">SCHEMA</div><div class="meta-val">' +
          this.esc(s.schemaUrl) + ' &nbsp; ' + specBadge + '</div></div>';
      }
      if (s.headers && s.headers.length > 0) {
        var tags = '';
        for (var j = 0; j < s.headers.length; j++) {
          tags += '<span class="tag">' + this.esc(s.headers[j].key) + '</span>';
        }
        meta += '<div class="meta-row"><div class="meta-key">HEADERS</div><div class="meta-val">' + tags + '</div></div>';
      }
      if (s.oauthProvider) {
        var prov = this.oauthProviders.find(function(p) { return p.id === s.oauthProvider; });
        var oauthBadge = prov && prov.hasGrant
          ? '<span class="badge connected">' + this.esc(s.oauthProvider) + ' · connected</span>'
          : '<span class="badge disconnected">' + this.esc(s.oauthProvider) + ' · not connected</span>';
        meta += '<div class="meta-row"><div class="meta-key">OAUTH</div><div class="meta-val">' + oauthBadge + '</div></div>';
      }

      if (!meta) {
        meta = '<div class="meta-row"><div class="meta-key">STATUS</div><div class="meta-val">awaiting configuration</div></div>';
      }

      html += '<div class="' + cardClass + '">' +
        '<div class="card-row">' +
          '<div class="card-identity">' +
            '<div class="card-name">' + this.esc(s.name) + '</div>' +
            '<div class="card-id">' + this.esc(s.id) + '</div>' +
          '</div>' +
          '<div class="card-badges">' + badges + '</div>' +
        '</div>' +
        '<div class="card-meta">' + meta + '</div>' +
        '<div class="card-actions">' +
          '<button type="button" class="row-btn" onclick="App.editServer(\'' + s.id + '\')">Edit</button>' +
          '<button type="button" class="row-btn accent" onclick="App.showTools(\'' + s.id + '\')">Tools</button>' +
          (isOpenapi ? '<button type="button" class="row-btn" onclick="App.refreshSpec(\'' + s.id + '\')">Reload schema</button>' : '') +
          '<button type="button" class="row-btn" onclick="App.toggleServer(\'' + s.id + '\')">' + (s.enabled ? 'Disable' : 'Enable') + '</button>' +
          '<button type="button" class="row-btn danger" onclick="App.removeServer(\'' + s.id + '\')">Remove</button>' +
        '</div>' +
        '<div id="server-tools-' + s.id + '"></div>' +
      '</div>';
    }

    container.innerHTML = html;

    // reopen tool panel if it was showing
    if (this.openTools) {
      var stillHere = this.servers.find(function(x) { return x.id === App.openTools; });
      if (stillHere) this.showTools(this.openTools);
      else this.openTools = null;
    }

    // set OAuth dropdown value in edit card
    if (this.editing) {
      var s2 = this.servers.find(function(x) { return x.id === App.editing; });
      if (s2) {
        var sel = document.querySelector('#edit-' + s2.id + ' .edit-oauth');
        if (sel) sel.value = s2.oauthProvider || '';
      }
    }
  },

  renderProviderEdit: function(p) {
    var secretLabel = p.hasSecret
      ? 'CLIENT SECRET <span class="label-tag">● SAVED</span>'
      : 'CLIENT SECRET';
    var secretPlaceholder = p.hasSecret ? '●●●●●●●●  (leave blank to keep)' : 'client secret';
    var secretHint = p.hasSecret
      ? 'stored on your ship — type a new value to replace it'
      : 'required';
    return '' +
    '<div class="oauth-card editing" id="edit-provider-' + p.id + '">' +
      '<div class="card-row">' +
        '<div class="card-identity">' +
          '<div class="card-name">Editing · ' + this.esc(p.id) + '</div>' +
          '<div class="card-id">' + this.esc(p.id) + '</div>' +
        '</div>' +
      '</div>' +
      '<div class="edit-form">' +
        '<div class="form-grid">' +
          '<label class="field"><span class="field-label">CLIENT ID</span>' +
            '<input type="text" class="edit-p-client-id" value="' + this.esc(p.clientId || '') + '"></label>' +
          '<label class="field"><span class="field-label">' + secretLabel + '</span>' +
            '<input type="password" class="edit-p-secret" placeholder="' + secretPlaceholder + '" autocomplete="new-password">' +
            '<span class="field-hint">' + secretHint + '</span>' +
          '</label>' +
        '</div>' +
        '<div class="form-grid">' +
          '<label class="field"><span class="field-label">AUTH URL</span>' +
            '<input type="url" class="edit-p-auth-url" value="' + this.esc(p.authUrl || '') + '"></label>' +
          '<label class="field"><span class="field-label">TOKEN URL</span>' +
            '<input type="url" class="edit-p-token-url" value="' + this.esc(p.tokenUrl || '') + '"></label>' +
        '</div>' +
        '<div class="form-grid">' +
          '<label class="field"><span class="field-label">REDIRECT URI</span>' +
            '<input type="url" class="edit-p-redirect" value="' + this.esc(p.redirectUri || '') + '"></label>' +
          '<label class="field"><span class="field-label">REVOKE URL</span>' +
            '<input type="url" class="edit-p-revoke-url" value="' + this.esc(p.revokeUrl || '') + '" placeholder="(optional)"></label>' +
        '</div>' +
        '<label class="field field-full"><span class="field-label">SCOPES</span>' +
          '<input type="text" class="edit-p-scopes" value="' + this.esc(p.scopes || '') + '"></label>' +
        '<div class="form-actions">' +
          '<button type="button" class="row-btn" onclick="App.cancelProviderEdit()">Cancel</button>' +
          '<button type="button" class="primary-btn" onclick="App.saveProvider(\'' + p.id + '\')">Save changes</button>' +
        '</div>' +
      '</div>' +
    '</div>';
  },

  renderOAuth: function() {
    var container = document.getElementById('oauth-providers');
    if (this.oauthProviders.length === 0) {
      container.innerHTML =
        '<div class="empty">NO PROVIDERS CONFIGURED' +
        '<em>link an upstream to OAuth by adding a provider above</em></div>';
      return;
    }

    // count which upstreams use each provider
    var usageMap = {};
    for (var i = 0; i < this.servers.length; i++) {
      var srv = this.servers[i];
      if (srv.oauthProvider) {
        usageMap[srv.oauthProvider] = (usageMap[srv.oauthProvider] || []).concat([srv.id]);
      }
    }

    var html = '';
    for (var k = 0; k < this.oauthProviders.length; k++) {
      var p = this.oauthProviders[k];
      if (this.editingProvider === p.id) { html += this.renderProviderEdit(p); continue; }
      var connected = p.hasGrant;
      var users = usageMap[p.id] || [];
      var usersHtml = users.length > 0
        ? users.map(function(u) { return '<span class="tag">' + App.esc(u) + '</span>'; }).join('')
        : '<span style="color:var(--paper-fade);font-style:italic">unused</span>';

      html += '<div class="oauth-card">' +
        '<div class="card-row">' +
          '<div class="card-identity">' +
            '<div class="card-name">' + this.esc(p.id) + '</div>' +
            '<div class="card-sub">oauth2 + pkce</div>' +
          '</div>' +
          '<div class="card-badges">' +
            '<span class="badge ' + (connected ? 'connected' : 'disconnected') + '">' +
              (connected ? 'connected' : 'disconnected') +
            '</span>' +
          '</div>' +
        '</div>' +
        '<div class="card-meta">' +
          (p.authUrl ? '<div class="meta-row"><div class="meta-key">AUTH URL</div><div class="meta-val">' + this.esc(p.authUrl) + '</div></div>' : '') +
          (p.scopes ? '<div class="meta-row"><div class="meta-key">SCOPES</div><div class="meta-val">' + this.esc(p.scopes) + '</div></div>' : '') +
          '<div class="meta-row"><div class="meta-key">USED BY</div><div class="meta-val">' + usersHtml + '</div></div>' +
        '</div>' +
        '<div class="card-actions">' +
          '<button type="button" class="row-btn" onclick="App.editProvider(\'' + p.id + '\')">Edit</button>' +
          (connected
            ? '<button type="button" class="row-btn danger" onclick="App.disconnectProvider(\'' + p.id + '\')">Disconnect</button>'
            : '<button type="button" class="row-btn accent" onclick="App.connectProvider(\'' + p.id + '\')">Connect</button>') +
          '<button type="button" class="row-btn danger" onclick="App.removeProvider(\'' + p.id + '\')">Remove</button>' +
        '</div>' +
      '</div>';
    }
    container.innerHTML = html;
  },

  esc: function(str) {
    if (str === null || str === undefined) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
};

document.addEventListener('DOMContentLoaded', function() { App.init(); });
