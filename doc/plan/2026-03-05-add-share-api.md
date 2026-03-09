# Add Share API Endpoint

## Context

Mobile apps have Share Sheets (iOS/Android) and don't need special Share functionality from Kaya Server. Desktop apps lack Share Sheets and need the server to provide public URLs via an API.

The web app already has sharing: a user can share an anga from its Preview screen, which generates a public URL using the `share_anga_url` helper. We need to expose this as an authenticated API route.

## Plan

### New Route

```
POST /api/v1/:user_email/share/anga/:filename
```

### New Controller

`Api::V1::ShareController < Api::V1::BaseController`

- Inherits HTTP Basic Auth from `BaseController`
- Uses `authorize_user_access` (same pattern as `AngaController`)
- Looks up the anga by encoded filename
- Returns JSON with the public share URL:

```json
{
  "share_url": "https://example.com/share/:user_id/anga/:filename"
}
```

- Returns 404 if anga not found

### Tests

- 401 without authentication
- 403 when accessing another user's namespace
- 404 for non-existent anga
- 200 with correct share URL for existing anga
- Correct URL encoding for filenames with special characters

### Files Changed

1. `config/routes.rb` — add `post "share/anga/:filename"` route
2. `app/controllers/api/v1/share_controller.rb` — new controller
3. `test/controllers/api/v1/share_controller_test.rb` — new tests
