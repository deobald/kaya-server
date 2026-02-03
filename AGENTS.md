# Kaya Developer Guide for AI Assistants

This document provides guidance for AI assistants working on the Kaya Server codebase. Kaya is a very simple, immutable, local-first-friendly note-taking and bookmarking platform.

The Kaya Server allows users to create accounts, store, and search their notes and bookmarks. Although Kaya Server allows users to store notes and bookmarks, users' primary method of interaction is using browser plugins, mobile apps, and desktop apps.

## Planning

Read [doc/plan/README.md](./doc/plan/README.md) and follow those instructions for creating a plan before any work is performed.

---

## Prompt History

You can find a chronological list of significant past prompts in [PROMPTS.md](PROMPTS.md). Major prompts are titled with Subheading Level Two (\#\#), sub-prompts are titled with Subheading Level Three (\#\#\#).

The current major prompt or bugfix will probably also be in this file, uncommitted.

This file will get large, over time, so only prioritize reading through it if you require additional context.

---

## Essential Commands

* `rails s` to start the server
* `rake test` to run unit tests
* `rake` provides most other commands, as this is a standard Rails project
* `ngrok http 80` for reverse proxy (mostly not needed)

---

## Codebase Overview

**Backend:**

* Ruby 3.4.8 / Rails 8.1
* PostgreSQL 17 (with pgcrypto, pg\_trgm extensions)

**Frontend:**

* Hotwire (Turbo Rails + Stimulus)

**Key Libraries:**

* File Storage:   ActiveStorage
* Authentication: Rails 8
* OAuth 2.0:      OmniAuth
* Versioning:     Paper Trail 17

---

## Core Concept

The simplicity of Kaya comes from a very simple concept: that notes and bookmarks are just files on disk, each named in a sequential fashion, following a `YYYY-mm-ddTHHMMSS` format, in UTC. These files are _immutable_, meaning that the user records one and then never touches it again. The timestamp associated with the file corresponds to the time (in UTC) the user made the record. In the rare case when there is a sub-section collision, the filename prefix format is `YYYY-mm-ddTHHMMSS_SSSSSSSSS`, representing nanoseconds.

The core functionality of Kaya comes from retrieval: looking up old notes, bookmarks, and files.

Anga (notes, bookmarks, and files) use this Core Concept, but it also applies to metadata files and other immutable data within the system. This makes it easy for Kaya clients to use peer-to-peer folder synchronization to stay up to date with one another, without Kaya Server.

---

## Domain Model

### Kāya, the "heap"

"Kāya" means a "heap" or "collection" in Pāli. It refers to each user's timestamped pile of files. To simplify spelling, the program name is simply `Kaya`, without the diacritical mark.

### Aṅga, the "part"

"Aṅga" means "constituent part" or "limb" in Pāli. Every timestamped record in the user's heap is one constituent part. To simplify spelling, the model is simply `Anga`, without the diacritical mark.

**Anga File Types:**

* `.md` - Markdown files are notes
* `.url` - URL files, in the style of Microsoft Windows, are bookmarks
* `.*` - any other file types (images, PDFs, etc.) are simply stored as-is

---

## Storage

Each user's list (kaya) of files (anga) is stored in a directory under ActiveStorage, named for that user's email address. These correspond directly to a list of files available from a namespaced API endpoint:

* `/api/v1/:user_email/anga/`

See "API" for more details.

---

## API

The primary interface to Kaya is its API. The API allows users to authenticate their client using the plain email and password associated with their `User` model, using HTTP Basic Authentication. The API is globally versioned, namespaced by the user's email, and all API endpoints are authenticated.

**APIs:**

* GET `/api/v1/handshake` - allows the client to discover this user's namespaced API endpoint
* GET `/api/v1/:user_email/anga` - returns a `text/plain` mimetype containing a simple, flat list of files with the format mentioned under "Core Concept": `2025-06-28T120000-note-to-self-example.md` so that clients can "diff" their list of files with the server's list of files for a given user
* GET `/api/v1/:user_email/anga/:filename` - returns the file as though it were accessed directly via Apache or nginx
* POST `/api/v1/:user_email/anga/:filename` - allows the client to directly POST one file a `multipart/form-data` Content-Type with correct Content-Type (MIME type) set on parts or a `application/octet-stream` Content-Type with raw binary file data and the file's MIME type is derived from the file extension
  * if the filename in the `Content-Disposition` does not match the un-escaped filename in the URL, the POST is rejected with a 417 HTTP error
  * if the filename in either the `Content-Disposition` or the URL collides with an existing filename at that same URL, the POST is rejected with a 409 HTTP error

---

## Architecture

Kaya relies on fat models, service objects, and thin views. Where possible, JavaScript is kept to a minimum in favour of backend Ruby code.

### Architecture Documentation

* [`doc/arch/`](doc/arch/) contains Architectural Decision Records

### Testing

* only permit a few integration tests
* only permit about 12 system tests across the entire repository
* unit tests should test models heavily, controllers lightly, and views not at all
* when fixing bugs, always try to write a failing unit test first; keep the test

### Logging

**Always add appropriate logs during development.**

**Log levels:**
- `debug` - Debug: State transitions, method entry/exit, variable values
- `info` - Info: Key milestones, user actions, important state changes
- `warn` - Warn: Unexpected but recoverable situations
- `error` - Error: Caught exceptions, failures (always include the exception)

**Where to add logs:**
- Effect handlers / side effect execution
- Repository/storage classes: Log I/O operations and results
- UI controllers: Log lifecycle events and user actions
- Caught exceptions: Always include the exception object

> **Tip**: Consider emoji prefixes (🟢 DEBUG, 🔵 INFO, 🟠 WARN, 🔴 ERROR) for quick visual scanning in development logs.

---

## Design

* [`doc/design/`](doc/design/) contains example icons, graphics, and design documentation for user interfaces and user experiences

Visual design should follow the [GNOME brand guidelines](https://brand.gnome.org/) for typography and colors.

UI and UX should follow the [GNOME Human Interface Guidelines](https://developer.gnome.org/hig/) to the extent that they apply to the web.

---

## Development Workflows

When adding a new feature:

1. Understand the domain - Read related models and tests
2. Check existing patterns - Look for similar features
3. Plan data model changes - Migrations follow Rails conventions
4. Implement in layers:
  * Models (business logic, validations, state machines)
  * Jobs (async processing)
  * Controllers (user input boundary)
  * Views/Components (UI)
5. Add stamps - Event tracking for visibility
6. Write tests - Factories, specs following existing patterns
7. Update docs - If adding new patterns/conventions:
  * keep it light
  * do not add to `doc/arch/adr-*.md` without asking
8. Never perform git commands

---

## Stimulus Controllers

### Key Principles

1. **Use declarative actions, not imperative event listeners**
2. **Keep controllers lightweight** (< 7 targets)
3. **Single responsibility** per controller
4. **Component controllers** stay in their component

### Declarative Pattern

**BAD - Imperative:**

```javascript
// Don't do this!
export default class extends Controller {
  static targets = ["button", "content"]

  connect() {
    this.buttonTarget.addEventListener("click", this.toggle.bind(this))
  }

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
```

**GOOD - Declarative:**

```erb
<!-- Declare in HTML -->
<div data-controller="toggle">
  <button data-action="click->toggle#toggle" data-toggle-target="button">
    Show
  </button>
  <div data-toggle-target="content" class="hidden">
    Hello World!
  </div>
</div>
```

```javascript
// Controller just responds
export default class extends Controller {
  static targets = ["button", "content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.buttonTarget.textContent =
      this.contentTarget.classList.contains("hidden") ? "Show" : "Hide"
  }
}
```
