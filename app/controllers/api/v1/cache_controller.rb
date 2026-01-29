module Api
  module V1
    class CacheController < BaseController
      # GET /api/v1/cache
      # Lists all cached bookmark directories
      def index
        bookmarks = current_user.angas
                                .joins(:bookmark)
                                .where.not(bookmarks: { cached_at: nil })
                                .order(filename: :asc)

        # Return list of cache directory names (same as anga filenames)
        directory_list = bookmarks.pluck(:filename).join("\n")

        render plain: directory_list, content_type: "text/plain"
      end

      # GET /api/v1/cache/:bookmark
      # Lists all files in a cached bookmark directory
      def show
        anga = current_user.angas.find_by(filename: params[:bookmark])

        unless anga&.bookmark&.cached?
          head :not_found
          return
        end

        file_list = anga.bookmark.cached_file_list.join("\n")
        render plain: file_list, content_type: "text/plain"
      end

      # GET /api/v1/cache/:bookmark/:filename
      # Returns a specific cached file
      def file
        anga = current_user.angas.find_by(filename: params[:bookmark])

        unless anga&.bookmark&.cached?
          head :not_found
          return
        end

        bookmark = anga.bookmark
        filename = params[:filename]

        if filename == "index.html" && bookmark.html_file.attached?
          send_data bookmark.html_file.download,
                    filename: "index.html",
                    type: "text/html",
                    disposition: "inline"
        elsif filename == "favicon.ico" && bookmark.favicon.attached?
          send_data bookmark.favicon.download,
                    filename: "favicon.ico",
                    type: bookmark.favicon.content_type,
                    disposition: "inline"
        else
          asset = bookmark.assets.find { |a| a.filename.to_s == filename }
          if asset
            send_data asset.download,
                      filename: filename,
                      type: asset.content_type,
                      disposition: "inline"
          else
            head :not_found
          end
        end
      end
    end
  end
end
