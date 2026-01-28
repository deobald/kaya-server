# Prompt Drafts

If you are an LLM, maybe don't bother reading this file. It's for human drafting to talk to you.

## Basic Full-Text Search

The search should look beyond filenames, into the contents of each file with with the `amatch` gem and Jaro-Winkler distance. For example, the contents of Markdown (notes) file/anga should be searched for matches directly and PDF files/anga should be searched using the `pdf-reader` gem. Abstract search into an object model with an entry point in [@services](file:///home/steven/work/deobald/kaya-server/app/services) but which delegates to leaf objects in [@models](file:///home/steven/work/deobald/kaya-server/app/models) beyond orchestration. For now, it will not be possible to search bookmarks this way, but you should create a `BookmarkSearch` service object similar to the service objects for notes and PDFs which just returns a match based on filename, for now. Eventually, we'll add a feature to pre-cache webpages alongside the anga files so that the bookmarks can be searched locally as well.
