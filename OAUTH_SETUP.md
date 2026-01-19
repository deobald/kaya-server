# OAuth Authentication Setup Guide

This application supports authentication via Google, Apple, and Microsoft OAuth providers.

## Environment Variables

Copy `.env.example` to `.env` and fill in your OAuth credentials:

```bash
cp .env.example .env
```

## OAuth Provider Setup

### Google OAuth2

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select an existing one
3. Click "Create Credentials" → "OAuth 2.0 Client ID"
4. Configure the OAuth consent screen if you haven't already
5. Choose "Web application" as the application type
6. Add authorized redirect URIs:
   - Development: `http://localhost:3000/auth/google_oauth2/callback`
   - Production: `https://yourdomain.com/auth/google_oauth2/callback`
7. Copy the Client ID and Client Secret to your `.env` file

**Required Scopes**: `email`, `profile`

### Apple Sign In

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/serviceId)
2. Create a new Service ID (or use existing one)
3. Enable "Sign in with Apple"
4. Configure domains and redirect URLs:
   - Development: `http://localhost:3000/auth/apple/callback`
   - Production: `https://yourdomain.com/auth/apple/callback`
5. Create a new Key for "Sign in with Apple"
6. Download the private key (.p8 file)
7. Add to your `.env` file:
   - `APPLE_CLIENT_ID`: Your Service ID
   - `APPLE_TEAM_ID`: Your Team ID (found in membership details)
   - `APPLE_KEY_ID`: The Key ID you created
   - `APPLE_PRIVATE_KEY`: Contents of the .p8 file (entire private key)

**Required Scopes**: `email`, `name`

### Microsoft OAuth2

1. Go to [Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
2. Click "New registration"
3. Enter a name for your application
4. Choose supported account types (e.g., "Accounts in any organizational directory and personal Microsoft accounts")
5. Add redirect URIs under "Web":
   - Development: `http://localhost:3000/auth/microsoft_graph/callback`
   - Production: `https://yourdomain.com/auth/microsoft_graph/callback`
6. Go to "Certificates & secrets" and create a new client secret
7. Copy the Application (client) ID and client secret value to your `.env` file

**Required Scopes**: `openid`, `email`, `profile`

## How It Works

### User Creation

When a user signs in with OAuth for the first time:

1. The system checks if an Identity exists for that provider + uid
2. If not, it looks for an existing User with the same email address
3. If no user exists, a new User is created with:
   - Email from the OAuth provider
   - A randomly generated secure password (since they'll login via OAuth)
4. An Identity record is created linking the User to the OAuth provider

### Multiple OAuth Providers

Users can link multiple OAuth providers to the same account if they share the same email address. For example:
- User signs in with Google (email: user@example.com) → User created
- Later signs in with Microsoft (email: user@example.com) → Same user, new Identity created
- User now has both Google and Microsoft linked to their account

### Email/Password Users

Users who sign up with email/password can later link OAuth providers by:
1. Signing in with email/password
2. Going to account settings (to be implemented)
3. Linking an OAuth provider

OAuth users can similarly set a password if needed.

## Database Schema

### Users Table (UUID Primary Key)
- `id` (uuid): Primary key
- `email_address` (string): Unique email address
- `password_digest` (string): Optional - can be null for OAuth-only users
- `created_at`, `updated_at`

### Identities Table
- `id` (integer): Primary key
- `user_id` (uuid): Foreign key to users table
- `provider` (string): OAuth provider name (google_oauth2, apple, microsoft_graph)
- `uid` (string): Unique identifier from OAuth provider
- `created_at`, `updated_at`
- Unique index on `[provider, uid]`

### Sessions Table
- `id` (integer): Primary key
- `user_id` (uuid): Foreign key to users table
- `ip_address` (string)
- `user_agent` (string)
- `created_at`, `updated_at`

## Testing OAuth Locally

For local development, you may need to:

1. Use `http://localhost:3000` as your callback URL (as configured above)
2. Some providers (especially Apple) may require HTTPS even in development
3. Consider using [ngrok](https://ngrok.com/) for HTTPS tunneling if needed:
   ```bash
   ngrok http 3000
   ```
   Then update your OAuth callback URLs to use the ngrok HTTPS URL

## Security Notes

1. Never commit `.env` to version control
2. Store production credentials in secure environment variable services
3. Use different OAuth applications for development and production
4. Regularly rotate client secrets
5. The randomly generated passwords for OAuth users are 64 characters (128-bit entropy) using SecureRandom

## Routes

- `POST /auth/:provider` - Initiates OAuth flow
- `POST /auth/:provider/callback` - OAuth callback handler
- `GET /auth/failure` - OAuth failure handler
