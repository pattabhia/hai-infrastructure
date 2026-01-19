# HAI Intel Keycloak Test Application

A simple Node.js/Express application to test the Keycloak OIDC integration.

## Quick Start

```bash
# Install dependencies
npm install

# Start the application
npm start
```

Then open http://localhost:3000 in your browser.

## Test Credentials

**Test User:**
- Username: `testuser`
- Password: `testpassword`
- Email: `testuser@haiintel.local`

**Keycloak Admin:**
- URL: http://localhost:8080/admin
- Username: `admin`
- Password: `admin`

## What This Tests

1. **OIDC Authorization Code Flow** with PKCE
2. **User Authentication** via Keycloak
3. **Token Exchange** (authorization code for access token)
4. **User Info Retrieval** from ID token claims
5. **Logout Flow** with redirect back to app

## Features

- ✅ Login with Keycloak
- ✅ Display user information
- ✅ Show access token (truncated)
- ✅ Logout functionality
- ✅ Link to Keycloak account management

## Configuration

The app is pre-configured to work with the local Keycloak instance:

- **Keycloak URL:** http://localhost:8080
- **Realm:** haiintel
- **Client ID:** haiintel-web
- **Client Secret:** 4sOG9ge1qaQkXvJyg4Z1mE8yWBPSzddL
- **Redirect URI:** http://localhost:3000/callback

## Managing Users and Groups

### Option 1: Via Keycloak Admin Console

1. Go to http://localhost:8080/admin
2. Login with `admin/admin`
3. Select the `haiintel` realm from the dropdown
4. Navigate to:
   - **Users** → Create/manage users
   - **Groups** → Create/manage groups (Users, Administrators, Developers already exist)
   - **Clients** → Manage OAuth/OIDC clients

### Option 2: Via JSON Configuration

Edit `keycloak-infra/config/realms/haiintel-realm.json` and add users/groups, then:

```bash
cd keycloak-infra
make stop
docker volume rm haiintel-keycloak-postgres-data
make start
```

This will reimport the realm with your changes.

### Option 3: Via Keycloak Admin CLI

```bash
# Create a new user
docker exec haiintel-keycloak /opt/keycloak/bin/kcadm.sh create users -r haiintel \
  -s username=newuser \
  -s email=newuser@haiintel.local \
  -s enabled=true

# Set user password
docker exec haiintel-keycloak /opt/keycloak/bin/kcadm.sh set-password -r haiintel \
  --username newuser \
  --new-password newpassword

# Add user to group
docker exec haiintel-keycloak /opt/keycloak/bin/kcadm.sh update users/<USER_ID>/groups/<GROUP_ID> -r haiintel
```

## Existing Groups

The realm comes with three pre-configured groups:

1. **Users** - Regular users
2. **Administrators** - Admin users
3. **Developers** - Developer users

You can assign users to these groups via the admin console or CLI.

