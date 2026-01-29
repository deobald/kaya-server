# Prompt Drafts

If you are an LLM, maybe don't bother reading this file. It's for human drafting to talk to you.

## Basic Full-Text Search

The search should look beyond filenames, into the contents of each file with with the `amatch` gem and Jaro-Winkler distance. For example, the contents of Markdown (notes) file/anga should be searched for matches directly and PDF files/anga should be searched using the `pdf-reader` gem. Abstract search into an object model with an entry point in [@services](file:///home/steven/work/deobald/kaya-server/app/services) but which delegates to leaf objects in [@models](file:///home/steven/work/deobald/kaya-server/app/models) beyond orchestration. For now, it will not be possible to search bookmarks this way, but you should create a `BookmarkSearch` service object similar to the service objects for notes and PDFs which just returns a match based on filename, for now. Eventually, we'll add a feature to pre-cache webpages alongside the anga files so that the bookmarks can be searched locally as well.

### Bug: matching common words

The search should not match heavily-reused words, such as "note" or "bookmark" from filenames. These are automatically created by clients and will be seen often. For example, "Notwithstanding" should match a PDF containing that exact text, but should not match `2026-01-21T164145-note.md` due to fuzzy search. If the user searches exactly for "note" or "bookmark", then circumvent this rule and return `.md` or `.url`, as they are probably expecting to see.

### Bug: search box focus is jumping

At a medium typing speed, the search box focus seems to "jump" into the middle of the existing text. I believe this is happening because of the search box being refocused. While typing the word "Notwithstanding", the cursor jumped multiple times within the textbox to produce "nwithtandingsot"

Why does the textbox lose focus on search at all? Since this is incremental search, it should happen in the background as the user types. Instead of attempting to retain cursor position OR default to refocusing at the end of the search box, is it possible to avoid the search box losing focus at all so the user can just type naturally?

When searching for "pdf", the PDF file/anga is not returned. Similar to "note" and "bookmark", "pdf", "png", and other filename extensions should normally not be matched... but they should match when the user types exactly "pdf" or ".pdf" (for example).

## Preview

Clicking on a tile in the search results should open that file. If it's a URL, open a modal overlay which will contain the contents of the webpage (once we cache it), with an option labelled "visit original page" that, when clicked, opens that URL in a new tab/window. If it's a note (.md), show the text of that note in a modal overlay so the user can read and copy it. If it's an image, show the image in a similar modal overlay. If it's a PDF, render the PDF in a modal overlay so the user can scroll through the pages, read, and copy text. Follow the GNOME HIG for the modal overlay, as per AGENTS.md.

### Refactor: Extract FileType model

Extract a `FileType` model which is used to wrap behaviour like `File.extname` and mapping to `preview_type` in index.html.erb. Anywhere in the codebase where `.md`, `.url`, `.pdf` and so on are hard-coded, the associated behaviour should move into the `FileType` model.

## Add a Note/Bookmark/File

To the immediate right of the hamburger menu in the header, add a plus icon (use the GNOME icon `plus-large-circle-symbolic.svg` found in /doc/design). Clicking this plus icon should bring up an "Add" modal. The "Add" modal should share the design with the "Preview" modal. The "Add" modal should contain a textbox with "Enter bookmark/note..." as the input placeholder and a "Save" button in the pill style of a modern, standard GNOME app.

**Notes and Bookmarks**: The "Save" operation should differentiate between bookmarks and notes based on whether or not they are prefixed with an HTTP protocol like "http://" or "https://". If so, the text is a bookmark and should be saved as a `.url` file (anga) in ActiveStorage after having leading and trailing whitespace stripped first. If not, the text is just a note and should be saved as a `.md` file (anga) in ActiveStorage.

**Drag & Drop**: The entire "Add" modal should also accept drag and drop events. If text is dropped, it should record a note/bookmark, according to instructions above, named with a `-note.md` or `-bookmark.url` suffix, respectively. If a file is dropped, `.md` files should be recorded as Notes. `.url` files should be recorded as Bookmarks. All other files should be recorded

**Filename Format**: The filename of dropped files should always be preserved, even for Notes and Bookmarks. All files/anga should have their filename prefixed with a datetimestamp according to the "Core Concept" as described in AGENTS.md

## Cached Webpages

When the user adds a URL with the "Add" modal, Kaya should use the `http.rb` gem to download the webpage. Create a model named `Bookmark` which will have attached ActiveStorage files for the HTML, JavaScript, CSS, and images required to re-render the webpage in the "Preview" modal window.

Add a `/api/v1/cache/` route which will list all cached `.url` (bookmark) angas, as directories (as 'text/plain', similar to AngaController#index). The cache index is used so Kaya clients can synchronize/diff with the Kaya Server. Add a `/api/v1/cache/:bookmark` route which returns the index of the directory which lists all the HTML, JavaScript, CSS, images, etc. required to re-render the webpage that was cached when the bookmark was saved. The names of cache directories (and, therefore, `:bookmark` in the route) should be identical to the filename of the anga: `2026-01-27T120000-bookmark.url` or similar.

Modify the "Preview" modal such that it renders the cached webpage for bookmark angas (`.url`) in an iframe, similar to how PDFs are rendered.

### Preview Webpage in Tile

If a bookmark has a cached version available, it should render a preview of the upper-left corner of the cached webpage in the tile, instead of the [@_bookmark_icon.html.erb](file:///home/steven/work/deobald/kaya-server/app/views/shared/icons/_bookmark_icon.html.erb) SVG. Restrict the size of the rendered webpage to the size of the tile and do not allow any of the elements to be clickable/selectable within the tile -- the tile should remain as a single unit and clicking anywhere on the tile should still render the "Preview" modal.

The tile doesn't appear to be rendering the preview at all. For now, instead of rendering a preview of the webpage itself in the tile, just render the original website's favicon at the same size as [@_bookmark_icon.html.erb](file:///home/steven/work/deobald/kaya-server/app/views/shared/icons/_bookmark_icon.html.erb) ... cache the favicon when a website is recorded with the "Add" dialog, though, and make it available through the `/api/v1/cache/:bookmark` routes. The tile should render this cached version of the favicon. If there is no cache, continue to display [@_bookmark_icon.html.erb](file:///home/steven/work/deobald/kaya-server/app/views/shared/icons/_bookmark_icon.html.erb) as the default.

When a tile is clicked but the webpage hasn't been cached yet, it says "Webpage is being cached..." -- this should actually occur, if the website is not in the cache and that message is shown. Adjust the caching mechanism to run in a SolidQueue ActiveJob and allow the frontend to initiate the download and caching of a webpage whenever this message is shown, via that job on the backend. The tile UI should poll, and re-render itself once the website has been cached and can be shown to the user from files in ActiveStorage.

**Bug:** The "Caching webpage..." spinner never returns. Even if it's left to run for an hour, the webpage hasn't been cached, the spinner hasn't been replaced by the webpage content, and the favicon and webpage contents are not showing up in the Preview modal even after a page refresh.

Write a system test (https://guides.rubyonrails.org/testing.html#system-testing) using Capybara to test the caching behaviour when a bookmark's Preview modal has been opened. The test should verify that the "Caching webpage..." spinner is replaced by the iframe once the webpage is downloaded and cached. Use https://www.postgresql.org/ as the sample domain/bookmark for the test.

## Searching Bookmarks

Now that bookmarks are downloaded as full webpages and successfully cached, add full-text search to BookmarkSearch as we had originally planned. It should search the text of the HTML document, similar to how PDFs are searched, but it does not need to load any of the other assets.

## Search Results

Search results should be ordered by relevance in the UI, starting with the most relevant. At the moment, it seems they are ordered based on their regular ("everything") order, even when returned as search results.

### BUG: Mid-filename text not found

In development, I have a file/anga called `2026-01-28T205243-three-button-mooze.png`. However, when I search for "button", it isn't returned. Is this because of the string difference fuzzy search used? If so, swap out Jaro-Winkler for Levenshtein. If it's a bug in the Search models, fix that instead.
