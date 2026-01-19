const express = require('express');
const session = require('express-session');
const { Issuer, generators } = require('openid-client');

const app = express();
const PORT = 8000;

// Configuration
const KEYCLOAK_URL = 'http://localhost:8080';
const REALM = 'haiintel';
const CLIENT_ID = 'haiintel-web';
const CLIENT_SECRET = '4sOG9ge1qaQkXvJyg4Z1mE8yWBPSzddL';
const REDIRECT_URI = 'http://localhost:8000/callback';

// Session middleware
app.use(session({
  secret: 'test-secret-change-in-production',
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // Set to true in production with HTTPS
}));

let client;

// Initialize OpenID Client
async function initializeClient() {
  const issuer = await Issuer.discover(`${KEYCLOAK_URL}/realms/${REALM}`);
  console.log('Discovered issuer:', issuer.metadata.issuer);

  client = new issuer.Client({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    redirect_uris: [REDIRECT_URI],
    response_types: ['code'],
  });

  console.log('OpenID Client initialized');
}

// Middleware to automatically refresh expired tokens
async function ensureValidToken(req, res, next) {
  // Skip if user is not logged in
  if (!req.session.refresh_token) {
    return next();
  }

  // Check if token is expired or about to expire (within 30 seconds)
  const now = Date.now();
  const expiresAt = req.session.token_expires_at || 0;
  const timeUntilExpiry = expiresAt - now;

  if (timeUntilExpiry < 30000) { // Less than 30 seconds until expiry
    console.log(`🔄 Access token expiring soon (${Math.floor(timeUntilExpiry / 1000)}s). Refreshing...`);

    try {
      // Use openid-client's refresh method
      const newTokenSet = await client.refresh(req.session.refresh_token);

      // Update session with new tokens
      req.session.access_token = newTokenSet.access_token;
      req.session.refresh_token = newTokenSet.refresh_token; // OAuth 2.1 rotation
      req.session.id_token = newTokenSet.id_token;
      req.session.userinfo = newTokenSet.claims();
      req.session.token_expires_at = Date.now() + (newTokenSet.expires_in * 1000);

      console.log(`✅ Token refreshed successfully. New expiry in ${newTokenSet.expires_in} seconds`);
    } catch (err) {
      console.error('❌ Token refresh failed:', err.message);

      // Clear session and redirect to login
      req.session.destroy();
      return res.redirect('/login');
    }
  }

  next();
}

// Routes
app.get('/', ensureValidToken, (req, res) => {
  if (req.session.userinfo) {
    const accessToken = req.session.access_token || '';
    const idToken = req.session.id_token || '';
    const expiresIn = req.session.token_expires_at ? Math.floor((req.session.token_expires_at - Date.now()) / 1000) : 0;

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>HAI Intel - Authenticated</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 1200px; margin: 50px auto; padding: 20px; }
          .user-info { background: #f0f0f0; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .user-info h2 { margin-top: 0; color: #333; }
          .user-info pre { background: white; padding: 15px; border-radius: 4px; overflow-x: auto; font-size: 12px; max-height: 300px; }
          .token-container { position: relative; }
          .copy-btn { position: absolute; top: 10px; right: 10px; padding: 8px 15px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 12px; }
          .copy-btn:hover { background: #218838; }
          .copy-btn.copied { background: #6c757d; }
          .btn { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; margin: 10px 5px 0 0; border: none; cursor: pointer; }
          .btn:hover { background: #0056b3; }
          .btn-danger { background: #dc3545; }
          .btn-danger:hover { background: #c82333; }
          .highlight { background: #fff3cd; padding: 2px 5px; border-radius: 3px; }
          .curl-example { background: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 4px; overflow-x: auto; font-family: monospace; font-size: 12px; }
          .token-status { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 4px; margin: 20px 0; }
          .token-status.warning { background: #fff3cd; border-color: #ffeaa7; color: #856404; }
          .token-status.expired { background: #f8d7da; border-color: #f5c6cb; color: #721c24; }
          .auto-refresh-badge { background: #28a745; color: white; padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        </style>
      </head>
      <body>
        <h1>✅ Successfully Authenticated with HAI Intel Keycloak!</h1>

        <div class="token-status ${expiresIn < 60 ? 'warning' : ''}">
          <strong>🔐 Token Status:</strong>
          Access token expires in <strong id="expires-in">${expiresIn}</strong> seconds
          <span class="auto-refresh-badge">AUTO-REFRESH ENABLED</span>
          <br><small>Token will automatically refresh when it has less than 30 seconds remaining</small>
        </div>

        <div class="user-info">
          <h2>User Information (from ID Token Claims)</h2>
          <pre>${JSON.stringify(req.session.userinfo, null, 2)}</pre>
        </div>

        <div class="user-info token-container">
          <h2>Access Token (JWT) - Use as Bearer Token</h2>
          <button class="copy-btn" onclick="copyToken('access-token')">📋 Copy Token</button>
          <pre id="access-token">${accessToken}</pre>
        </div>

        <div class="user-info token-container">
          <h2>ID Token (JWT)</h2>
          <button class="copy-btn" onclick="copyToken('id-token')">📋 Copy Token</button>
          <pre id="id-token">${idToken}</pre>
        </div>

        <div class="user-info">
          <h2>🔧 How to Use the Access Token</h2>
          <p>Copy the access token above and use it in API requests:</p>
          <div class="curl-example">
curl -H "Authorization: Bearer ${accessToken.substring(0, 50)}..." \\
     http://your-api-endpoint/resource
          </div>
          <p style="margin-top: 15px;">
            <strong>Decode JWT:</strong> Paste the token at
            <a href="https://jwt.io" target="_blank" style="color: #007bff;">jwt.io</a>
            to inspect claims, roles, and expiration.
          </p>
        </div>

        <div>
          <a href="/logout" class="btn btn-danger">Logout</a>
          <a href="/account" class="btn">Manage Account</a>
          <button onclick="testApiCall()" class="btn">🧪 Test API Call (Auto-Refresh)</button>
          <button onclick="window.open('https://jwt.io/#debugger-io?token=' + encodeURIComponent(document.getElementById('access-token').textContent.trim()), '_blank')" class="btn">🔍 Decode Access Token</button>
          <button onclick="window.open('https://jwt.io/#debugger-io?token=' + encodeURIComponent(document.getElementById('id-token').textContent.trim()), '_blank')" class="btn">🔍 Decode ID Token</button>
        </div>

        <div id="api-result" style="display: none; margin-top: 20px;">
          <div class="user-info">
            <h2>API Response</h2>
            <pre id="api-response"></pre>
          </div>
        </div>

        <script>
          // Token expiry countdown
          let expiresIn = ${expiresIn};

          function updateCountdown() {
            const element = document.getElementById('expires-in');
            const statusDiv = element.closest('.token-status');

            if (expiresIn > 0) {
              element.textContent = expiresIn;

              // Update styling based on time remaining
              if (expiresIn < 30) {
                statusDiv.className = 'token-status expired';
                statusDiv.querySelector('strong').textContent = '🔄 Token Status (REFRESHING):';
              } else if (expiresIn < 60) {
                statusDiv.className = 'token-status warning';
              } else {
                statusDiv.className = 'token-status';
              }

              expiresIn--;
            } else {
              // Token expired, reload page to trigger refresh
              console.log('Token expired, reloading page to get new token...');
              window.location.reload();
            }
          }

          // Update countdown every second
          setInterval(updateCountdown, 1000);

          // Test API call with automatic token refresh
          async function testApiCall() {
            const resultDiv = document.getElementById('api-result');
            const responseEl = document.getElementById('api-response');

            resultDiv.style.display = 'block';
            responseEl.textContent = 'Loading...';

            try {
              const response = await fetch('/api/userinfo');
              const data = await response.json();

              responseEl.textContent = JSON.stringify(data, null, 2);

              if (data.success) {
                console.log('✅ API call successful. Token expires in:', data.token_expires_in, 'seconds');
              }
            } catch (err) {
              responseEl.textContent = 'Error: ' + err.message;
            }
          }

          function copyToken(elementId) {
            const element = document.getElementById(elementId);
            const text = element.textContent.trim();

            navigator.clipboard.writeText(text).then(() => {
              const btn = element.previousElementSibling;
              const originalText = btn.textContent;
              btn.textContent = '✅ Copied!';
              btn.classList.add('copied');

              setTimeout(() => {
                btn.textContent = originalText;
                btn.classList.remove('copied');
              }, 2000);
            }).catch(err => {
              alert('Failed to copy: ' + err);
            });
          }
        </script>
      </body>
      </html>
    `);
  } else {
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>HAI Intel - Login</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; text-align: center; }
          h1 { color: #333; }
          .info { background: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: left; }
          .btn { display: inline-block; padding: 15px 30px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; font-size: 16px; margin-top: 20px; }
          .btn:hover { background: #0056b3; }
          .credentials { background: #fff3cd; padding: 15px; border-radius: 4px; margin: 10px 0; }
        </style>
      </head>
      <body>
        <h1>🔐 HAI Intel Keycloak Test Application</h1>
        <div class="info">
          <h2>Test Credentials</h2>
          <div class="credentials">
            <strong>Username:</strong> testuser<br>
            <strong>Password:</strong> testpassword<br>
            <strong>Email:</strong> testuser@haiintel.local
          </div>
          <p><strong>Realm:</strong> ${REALM}</p>
          <p><strong>Client ID:</strong> ${CLIENT_ID}</p>
          <p><strong>Keycloak URL:</strong> ${KEYCLOAK_URL}</p>
        </div>
        <a href="/login" class="btn">Login with Keycloak</a>
      </body>
      </html>
    `);
  }
});

app.get('/login', async (req, res) => {
  const code_verifier = generators.codeVerifier();
  const code_challenge = generators.codeChallenge(code_verifier);

  req.session.code_verifier = code_verifier;

  const authorizationUrl = client.authorizationUrl({
    scope: 'openid email profile',
    code_challenge,
    code_challenge_method: 'S256',
  });

  res.redirect(authorizationUrl);
});

app.get('/callback', async (req, res) => {
  try {
    const params = client.callbackParams(req);
    const tokenSet = await client.callback(REDIRECT_URI, params, {
      code_verifier: req.session.code_verifier,
    });

    // Store all tokens including refresh token
    req.session.access_token = tokenSet.access_token;
    req.session.refresh_token = tokenSet.refresh_token;
    req.session.id_token = tokenSet.id_token;
    req.session.userinfo = tokenSet.claims();
    req.session.token_expires_at = Date.now() + (tokenSet.expires_in * 1000);

    console.log(`✅ Tokens stored. Access token expires in ${tokenSet.expires_in} seconds`);

    res.redirect('/');
  } catch (err) {
    console.error('Callback error:', err);
    res.status(500).send(`Authentication failed: ${err.message}`);
  }
});

app.get('/logout', async (req, res) => {
  const id_token = req.session.id_token;
  req.session.destroy();

  const logoutUrl = client.endSessionUrl({
    id_token_hint: id_token,
    post_logout_redirect_uri: 'http://localhost:8000',
  });

  res.redirect(logoutUrl);
});

app.get('/account', (req, res) => {
  res.redirect(`${KEYCLOAK_URL}/realms/${REALM}/account`);
});

// API endpoint to demonstrate token usage with auto-refresh
app.get('/api/userinfo', ensureValidToken, async (req, res) => {
  if (!req.session.access_token) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  try {
    // Call Keycloak's userinfo endpoint with the access token
    const userinfo = await client.userinfo(req.session.access_token);

    res.json({
      success: true,
      userinfo: userinfo,
      token_expires_in: Math.floor((req.session.token_expires_at - Date.now()) / 1000),
      message: 'Token was automatically refreshed if needed'
    });
  } catch (err) {
    console.error('Userinfo error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Start server
initializeClient().then(() => {
  app.listen(PORT, () => {
    console.log(`\n🚀 HAI Intel Keycloak Test App running at http://localhost:${PORT}`);
    console.log(`\n📋 Test Credentials:`);
    console.log(`   Username: testuser`);
    console.log(`   Password: testpassword`);
    console.log(`\n🔗 Keycloak Admin: ${KEYCLOAK_URL}/admin`);
    console.log(`   Admin credentials: admin/admin\n`);
  });
}).catch(err => {
  console.error('Failed to initialize:', err);
  process.exit(1);
});

