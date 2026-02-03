# ADR 0005: Full Text Search

## Context

Because Kaya aims to be local-first, local search needs to be possible on edge devices, such as phones.

## Decision

Kaya Server will keep a plaintext copy of bookmarks, PDFs, and other anga which are difficult to search directly. On clients, these plaintext copies will be stored in `~/.kaya/text/` according to the following layout:

* `~/.kaya/text/` = root
* `~/.kaya/text/{bookmark}` = bookmark root
* `~/.kaya/text/{bookmark}/{filename}` = plaintext bookmark contents
* `~/.kaya/text/{pdf}` = pdf root
* `~/.kaya/text/{pdf}/{filename}` = plaintext pdf contents
* etc.

These three patterns are symmetrical to the 3 routes Kaya Server must expose:

* `/api/v1/:user_email/text`
* `/api/v1/:user_email/text/:anga`
* `/api/v1/:user_email/text/:anga/:filename`

When the user creates a new anga, whether directly through Kaya Server or indirectly via sync, Kaya Server enqueues a background job to transform it into a plaintext copy.

**API Mapping:**

* `~/.kaya/text/` <=> `/api/v1/:user_email/text`
* `~/.kaya/text/{anga}` <=> `/api/v1/:user_email/text/:anga`
* `~/.kaya/text/{anga}/{filename}` <=> `/api/v1/:user_email/text/:anga/:filename`

## Status

Accepted.

## Consequences

Cached contents for Full Text Search over both bookmarks and PDFs will allow both local search and server-side search to be much faster. These text files are also human-readable, which means they are useful directly to the user and can also be consumed by other tools.
