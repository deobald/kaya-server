# 2026-02-04-r-rename-text-to-words.md

Rename the `Text` model, table, API routes, and all related references to `Words` per ADR-0005.

## Scope

The rename targets the **full-text search plaintext copies** model (`Text`) and its ecosystem. It does **NOT** touch:

- `Search::TextSearch` / `file_type.text?` / `PREVIEW_TYPES[:text]` — these refer to `.txt` file extension handling
- Rails column types (`t.text`)
- MIME types (`"text/plain"`, `"text/markdown"`)
- Ruby gem methods (e.g., `reader.pages.map(&:text)` in PDF extraction)
- Generic uses of the word "text" in comments/log messages describing content

## ADR Updates

- `doc/arch/adr-0003-sync.md` — update `~/.kaya/text/` paths to `~/.kaya/words/`
  (ADR-0005 is already updated)

## Files to Rename (mv)

1. `app/models/text.rb` → `app/models/words.rb`
2. `app/controllers/api/v1/text_controller.rb` → `app/controllers/api/v1/words_controller.rb`
3. `db/migrate/20260203050229_create_texts.rb` → `db/migrate/20260203050229_create_words.rb`
4. `test/factories/texts.rb` → `test/factories/words.rb`
5. `test/models/text_test.rb` → `test/models/words_test.rb`
6. `test/controllers/api/v1/text_controller_test.rb` → `test/controllers/api/v1/words_controller_test.rb`

## Files to Edit (content changes)

### Model: `app/models/words.rb` (after rename)
- Schema comment: `Table name: texts` → `Table name: words`
- Index comment: `index_texts_on_anga_id` → `index_words_on_anga_id`
- Class: `Text` → `Words`
- Method: `text_filename` → `words_filename`
- Comment: update "text filename" references

### Model: `app/models/anga.rb`
- Callback: `setup_pdf_text` → `setup_pdf_words`
- Association: `has_one :text` → `has_one :words`
- Private method: `def setup_pdf_text` → `def setup_pdf_words`

### Controller: `app/controllers/api/v1/words_controller.rb` (after rename)
- Class: `TextController` → `WordsController`
- Comments: `/text` → `/words`
- Association calls: `.joins(:text)` → `.joins(:words)`, `anga&.text` → `anga&.words`
- Table reference: `texts:` → `words:`
- Variable: `text` → `words` (local var throughout)
- Method call: `text.text_filename` → `words.words_filename`

### Routes: `config/routes.rb`
- Comment: "Text API" → "Words API"
- Route paths: `"text"` → `"words"`
- Controller: `"text#index"` → `"words#index"`, etc.
- Route names: `"text"` → `"words"`, `"text_anga"` → `"words_anga"`, `"text_file"` → `"words_file"`

### Job: `app/jobs/extract_plaintext_bookmark_job.rb`
- Association: `anga.text` → `anga.words`, `anga.build_text` → `anga.build_words`
- Local var: `text` → `words` (throughout)

### Job: `app/jobs/extract_plaintext_pdf_job.rb`
- Association: `anga.text` → `anga.words`, `anga.build_text` → `anga.build_words`
- Local var: `text` → `words` (throughout)
- **Do NOT rename** `reader.pages.map(&:text)` — this is a PDF gem method

### Search: `app/models/search/pdf_search.rb`
- Association: `@anga.text` → `@anga.words`
- Local var: `text` → `words`
- Log message: "extracted text" → "extracted words"

### Search: `app/models/search/bookmark_search.rb`
- Comment: "Text model" → "Words model"
- Association: `@anga.text` → `@anga.words`
- Local var: `text` → `words`

### Search service: `app/services/search_service.rb`
- Eager load: `:text` → `:words` in the `.includes()` call

### Migration: `db/migrate/20260203050229_create_words.rb` (after rename)
- Class: `CreateTexts` → `CreateWords`
- Table: `:texts` → `:words`
- Index/FK references: `:texts` → `:words`

### Schema: `db/schema.rb`
- Updated `create_table "texts"` → `create_table "words"`
- Updated `index_texts_on_anga_id` → `index_words_on_anga_id`
- Updated `add_foreign_key "texts"` → `add_foreign_key "words"`

### Factory: `test/factories/words.rb` (after rename)
- Schema comment: `Table name: texts` → `Table name: words`
- Index comment: `index_texts_on_anga_id` → `index_words_on_anga_id`
- Factory name: `factory :text` → `factory :words`
- Local var in trait: `text` → `words`

### Model test: `test/models/words_test.rb` (after rename)
- Schema comment block: update table/index names
- Class: `TextTest` → `WordsTest`
- All `Text.new` → `Words.new`
- All `create(:text, ...)` → `create(:words, ...)`
- All `Text.count` → `Words.count`
- Method references: `text_filename` → `words_filename`

### Controller test: `test/controllers/api/v1/words_controller_test.rb` (after rename)
- Class: `Api::V1::TextControllerTest` → `Api::V1::WordsControllerTest`
- All `create(:text, ...)` → `create(:words, ...)`
- Route helpers: `api_v1_text_url` → `api_v1_words_url`, `api_v1_text_anga_url` → `api_v1_words_anga_url`, `api_v1_text_file_url` → `api_v1_words_file_url`
- Comments: `/text` → `/words`

### Job tests: `test/jobs/extract_plaintext_bookmark_job_test.rb`
- Association: `anga.text` → `anga.words`
- Method: `.text_filename` → `.words_filename`
- Build: `anga.create_text!` → `anga.create_words!`

### Job tests: `test/jobs/extract_plaintext_pdf_job_test.rb`
- Association: `anga.text` → `anga.words`, `anga_reloaded.text` → `anga_reloaded.words`
- Build: `anga.create_text!` → `anga.create_words!`

### Search tests: `test/models/search/pdf_search_test.rb`
- All `create(:text, ...)` → `create(:words, ...)`
- Local var: `text` → `words`

### Search tests: `test/models/search/bookmark_search_test.rb`
- All `create(:text, ...)` → `create(:words, ...)`
- Local var: `text` → `words`

### ADR: `doc/arch/adr-0003-sync.md`
- Path references: `~/.kaya/text/` → `~/.kaya/words/`, `/text` → `/words` in the mapping table

## Files NOT Changed

- `app/models/search/text_search.rb` — searches `.txt` files, not related to the Text/Words model
- `app/models/files/file_type.rb` — `text?`, `PREVIEW_TYPES[:text]`, `TEXT_EXTENSIONS` all refer to `.txt` files
- `app/services/search_service.rb` line 40 (`file_type.text?`) — refers to `.txt` file type
- `app/models/search/base_search.rb` — generic search, no Text model references

## Execution Order

1. Rename files (6 renames listed above)
2. Edit all file contents (model, controller, routes, jobs, search models, tests, factory, migration, ADR)
3. Run `rails db:drop db:create db:migrate` (since never deployed to production, the migration rename is safe)
4. Run `bundle exec annotaterb models` to regenerate schema annotations
5. Run `rake test` to verify all tests pass

## Verification

1. `rake test` — 161 tests pass, 0 failures, 0 errors
2. `rails routes | grep words` — shows the 3 words API routes
3. Stale reference check — no remaining references to the old `Text` model in app/ or test/
