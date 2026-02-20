# BUG: API file listings should not contain spaces

## Problem

Filenames are stored as-is (unencoded) in the database. The API `index` actions encode on output via `ERB::Util.url_encode`, but filenames with URL-unfriendly characters (spaces, commas, unicode, etc.) can still be saved to the DB by:

- `Api::V1::AngaController#create` — calls `CGI.unescape(params[:filename])` and saves the unescaped result
- `AngaController#generate_filename` — uses `original_filename` from uploads without encoding
- `Api::V1::MetaController#create` — same pattern as Anga

No model-level validation or normalization enforces URL-safe filenames.

## Approach

**Encode on save, serve as-is from DB, decode for UI display.**

`ERB::Util.url_encode` is the right encoding method — it preserves unreserved characters (`A-Za-z0-9`, `-`, `.`, `_`, `~`) and percent-encodes everything else (spaces become `%20`, etc.). The timestamp prefix (`2025-06-28T120000`) contains only safe characters, so it passes through unchanged.

### Shared concern: `FilenameEncoding`

Extract a `Concerns::FilenameEncoding` module used by both `Anga` and `Meta`:

```ruby
module Concerns::FilenameEncoding
  extend ActiveSupport::Concern

  included do
    before_validation :encode_filename
  end

  class_methods do
    def url_safe?(filename)
      filename.match?(/\A[A-Za-z0-9\-._~%]+\z/)
    end
  end

  private

  def encode_filename
    return if filename.blank?
    decoded = CGI.unescape(filename)
    self.filename = ERB::Util.url_encode(decoded)
  end
end
```

The `encode_filename` callback first decodes (to normalize any already-encoded input), then re-encodes. This is idempotent: encoding an already-safe filename produces the same result.

## Implementation Steps

### 1. Create `app/models/concerns/filename_encoding.rb`

Shared concern with `before_validation :encode_filename` and `url_safe?` class method.

### 2. Update `app/models/anga.rb`

- Include `Concerns::FilenameEncoding`

### 3. Update `app/models/meta.rb`

- Include `Concerns::FilenameEncoding`

### 4. Update `app/controllers/api/v1/anga_controller.rb`

- **`index`**: Replace `ERB::Util.url_encode` mapping with a safety-net that only encodes if not already safe (to avoid double-encoding now that DB stores encoded filenames):
  ```ruby
  safe_filenames = filenames.map { |f| Anga.url_safe?(f) ? f : ERB::Util.url_encode(f) }
  ```
- **`create`**: The `CGI.unescape(params[:filename])` + model callback handles encoding. The collision check must use the encoded filename. Filename mismatch comparison stays on decoded values.
- **`set_anga`**: Look up by `ERB::Util.url_encode(CGI.unescape(params[:filename]))` to match the DB's encoded form.

### 5. Update `app/controllers/api/v1/meta_controller.rb`

Same pattern as Step 4: safety-net in `index`, lookup by encoded name in `set_meta`, model handles encoding on create.

### 6. Update `app/controllers/api/v1/words_controller.rb`

- **`index`**: Same safety-net pattern.
- **`show`** and **`file`**: Look up anga by encoded filename.

### 7. Update `app/controllers/api/v1/cache_controller.rb`

- **`index`**: Same safety-net pattern.
- **`show`** and **`file`**: Look up anga by encoded filename.

### 8. Update `app/controllers/shares_controller.rb`

Look up by encoded filename: `ERB::Util.url_encode(CGI.unescape(params[:filename]))`.

### 9. Add `display_filename` helper to `app/helpers/application_helper.rb`

```ruby
def display_filename(filename)
  CGI.unescape(filename)
end
```

### 10. Update UI views

- `app/views/everything/index.html.erb`: Use `display_filename(anga.filename)` where filenames are shown to users.
- `app/javascript/controllers/preview_modal_controller.js`: Apply `decodeURIComponent()` to filenames for display.

### 11. Write tests (failing first, then fix)

**Model tests (`test/models/anga_test.rb`):**
- Filename with spaces is encoded on save
- Filename with unicode is encoded on save
- Already-encoded filename is not double-encoded
- Idempotent: saving twice doesn't change filename

**Model tests (`test/models/meta_test.rb`):**
- Same encoding tests as Anga

**Controller tests (`test/controllers/api/v1/anga_controller_test.rb`):**
- API index never returns filenames with spaces (even if DB has them)
- Creating a file with spaces stores encoded filename
- Show endpoint finds file by encoded filename
- Round-trip: create with spaces, list, fetch by listed name all works

**Controller tests for Meta, Words, Cache:**
- Same safety-net assertions as Anga

### 12. Create rake task `lib/tasks/filenames.rake`

`rake filenames:encode` — finds and re-encodes any existing filenames in the `angas` and `metas` tables that contain URL-unsafe characters.

### 13. Update `Meta#link_to_anga`

The `link_to_anga` callback looks up `user.angas.find_by(filename: anga_filename)`. Since anga filenames are now encoded in the DB, the `anga_filename` stored in Meta's TOML must also match the encoded form. The callback should encode the `anga_filename` before lookup.

## Files to Modify

| File | Change |
|------|--------|
| `app/models/concerns/filename_encoding.rb` | **NEW** — shared concern |
| `app/models/anga.rb` | Include concern |
| `app/models/meta.rb` | Include concern, update `link_to_anga` |
| `app/controllers/api/v1/anga_controller.rb` | Safety-net index, encoded lookups |
| `app/controllers/api/v1/meta_controller.rb` | Safety-net index, encoded lookups |
| `app/controllers/api/v1/words_controller.rb` | Safety-net index, encoded lookups |
| `app/controllers/api/v1/cache_controller.rb` | Safety-net index, encoded lookups |
| `app/controllers/shares_controller.rb` | Encoded lookup |
| `app/helpers/application_helper.rb` | `display_filename` helper |
| `app/views/everything/index.html.erb` | Use `display_filename` |
| `app/javascript/controllers/preview_modal_controller.js` | `decodeURIComponent` for display |
| `test/models/anga_test.rb` | Encoding tests |
| `test/models/meta_test.rb` | Encoding tests |
| `test/controllers/api/v1/anga_controller_test.rb` | Updated + new tests |
| `test/controllers/api/v1/meta_controller_test.rb` | Updated tests |
| `test/controllers/api/v1/words_controller_test.rb` | Updated tests |
| `test/controllers/api/v1/cache_controller_test.rb` | Updated tests |
| `lib/tasks/filenames.rake` | **NEW** — rake task to encode existing data |
