# Add Rake Task: `kaya:password:reset`

## Context

The user "reset password" feature does not work yet because there is no email service connected to Kaya Server. An administrator needs a way to manually reset a user's password from the command line.

## Approach

Add a Rake task `kaya:password:reset` under the existing `kaya` namespace (consistent with `kaya:text:extract_all` and `kaya:db_filenames:*`). The task accepts an email address as an environment variable, looks up the user, generates a new random password, updates the user's record, and prints the new password to stdout so the admin can communicate it to the user.

### Behavior

1. Accept the user's email via `EMAIL` environment variable: `rake kaya:password:reset EMAIL=user@example.com`
2. Look up the user by `email_address` (using the same normalization the model uses: strip + downcase)
3. If the user is not found, print an error and exit with a non-zero status
4. Generate a secure random password (16 hex characters = 32 chars, well above the 8-char minimum)
5. Update the user's password and set `incidental_password: false` (this is now an admin-assigned password, not an OAuth auto-generated one)
6. Print the new password to stdout
7. Log the reset at `info` level (without logging the password itself)

### Files to create/modify

- **`lib/tasks/password.rake`** - New file containing the `kaya:password:reset` task
- **`test/tasks/password_task_test.rb`** - Unit test for the rake task

### Questions

1. Should the generated password be a human-friendly format (e.g. `xkcd`-style words) or is a random hex string sufficient? I'll default to a random hex string for simplicity.
2. Should the task also clear existing sessions for the user (forcing re-login)? I'll default to yes, since a password reset implies the old credentials should be invalidated.
