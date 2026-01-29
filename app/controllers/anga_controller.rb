class AngaController < ApplicationController
  def preview
    @anga = Current.user.angas.find(params[:id])

    if @anga.file.attached?
      send_data @anga.file.download,
                filename: @anga.filename,
                type: @anga.file.content_type,
                disposition: "inline"
    else
      head :not_found
    end
  end

  # Returns cache status and triggers caching if needed
  def cache_status
    @anga = Current.user.angas.find(params[:id])
    bookmark = @anga.bookmark

    # If no bookmark record exists, try to create one from the .url file
    if bookmark.nil?
      file_type = FileType.new(@anga.filename)
      unless file_type.bookmark? && @anga.file.attached?
        render json: { error: "Not a bookmark" }, status: :unprocessable_entity
        return
      end

      # Extract URL from the .url file
      url = @anga.file.download.force_encoding("UTF-8")[/URL=(.+)/, 1]&.strip
      unless url.present?
        render json: { error: "Could not extract URL from bookmark file" }, status: :unprocessable_entity
        return
      end

      # Create the bookmark record
      bookmark = @anga.create_bookmark!(url: url)
    end

    # If already cached, return the cache URL
    if bookmark.cached?
      render json: {
        status: "cached",
        cache_url: app_anga_cache_file_path(@anga, "index.html"),
        favicon_url: bookmark.favicon.attached? ? app_anga_cache_file_path(@anga, "favicon.ico") : nil
      }
      return
    end

    # If caching failed, return error status
    if bookmark.cache_failed?
      render json: {
        status: "error",
        error: bookmark.cache_error
      }
      return
    end

    # If not cached and no error, run the caching job synchronously
    # This ensures the user sees results immediately rather than waiting for async processing
    CacheBookmarkJob.perform_now(bookmark.id)

    # Check the result after the job completes
    bookmark.reload

    if bookmark.cached?
      render json: {
        status: "cached",
        cache_url: app_anga_cache_file_path(@anga, "index.html"),
        favicon_url: bookmark.favicon.attached? ? app_anga_cache_file_path(@anga, "favicon.ico") : nil
      }
    elsif bookmark.cache_failed?
      render json: {
        status: "error",
        error: bookmark.cache_error
      }
    else
      render json: { status: "pending" }
    end
  end

  # Serves cached bookmark files (HTML and assets)
  def cache_file
    @anga = Current.user.angas.find(params[:id])
    bookmark = @anga.bookmark

    unless bookmark&.cached?
      head :not_found
      return
    end

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

  def create
    if params[:file].present?
      create_from_file
    elsif params[:content].present?
      create_from_text
    else
      render json: { error: "No content or file provided" }, status: :unprocessable_entity
    end
  end

  private

  def create_from_file
    uploaded_file = params[:file]
    original_filename = uploaded_file.original_filename
    filename = generate_filename(original_filename)

    anga = Current.user.angas.new(filename: filename)
    file_type = FileType.new(filename)

    anga.file.attach(
      io: uploaded_file.tempfile,
      filename: filename,
      content_type: file_type.content_type
    )

    if anga.save
      render json: { success: true, filename: filename }, status: :created
    else
      render json: { error: anga.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def create_from_text
    content = params[:content].to_s.strip
    type = params[:type]

    if type == "bookmark"
      filename = generate_filename("bookmark.url")
      file_content = "[InternetShortcut]\nURL=#{content}\n"
      content_type = "text/plain"
    else
      filename = generate_filename("note.md")
      file_content = content
      content_type = "text/markdown"
    end

    anga = Current.user.angas.new(filename: filename)
    anga.file.attach(
      io: StringIO.new(file_content),
      filename: filename,
      content_type: content_type
    )

    if anga.save
      # For bookmarks, create a Bookmark record and cache the webpage
      if type == "bookmark"
        cache_bookmark(anga, content)
      end

      render json: { success: true, filename: filename }, status: :created
    else
      render json: { error: anga.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def cache_bookmark(anga, url)
    bookmark = anga.create_bookmark(url: url)
    # Cache the webpage asynchronously to avoid blocking the response
    CacheBookmarkJob.perform_later(bookmark.id)
  end

  def generate_filename(original_name)
    timestamp = Time.now.utc.strftime("%Y-%m-%dT%H%M%S")
    base_filename = "#{timestamp}-#{original_name}"

    # Check for collision and add nanoseconds if needed
    if Current.user.angas.exists?(filename: base_filename)
      nanoseconds = Time.now.utc.nsec.to_s.rjust(9, "0")
      timestamp_with_ns = "#{timestamp}_#{nanoseconds}"
      "#{timestamp_with_ns}-#{original_name}"
    else
      base_filename
    end
  end
end
