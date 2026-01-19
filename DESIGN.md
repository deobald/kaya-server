# Kaya Design

* web API does not need to mirror #lofi / p2p future
* records (anga) are individual files, numbered:
  * `yyyy-MM-ddTHH-mm-ss-{filename}`

## API Routes

* /:user_email/angas  - POST to sync individual angas
* /:user_email/angas  - GET to list all angas by filename 
* /:user_email/sync   - POST any angas to synchronize in bulk
* /:user_email/search - GET to query for an anga

## Questions

* auth?
  * google, apple, microsoft
* shared folders? "spaces"?

## Priorities

* TypeScript GNOME app
* Rails API
* web UI comes last
