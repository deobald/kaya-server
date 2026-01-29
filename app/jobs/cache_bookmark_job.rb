class CacheBookmarkJob < ApplicationJob
  queue_as :default

  def perform(bookmark_id)
    bookmark = Bookmark.find_by(id: bookmark_id)
    return unless bookmark

    WebpageCacheService.new(bookmark).cache
  end
end
