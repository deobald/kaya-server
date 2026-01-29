require "nokogiri"

module Search
  class BookmarkSearch < BaseSearch
    protected

    # Extract text content from cached HTML for full-text search
    def extract_content
      bookmark = @anga.bookmark
      return nil unless bookmark&.cached? && bookmark.html_file.attached?

      begin
        html_content = bookmark.html_file.download
        doc = Nokogiri::HTML(html_content)

        # Remove script and style elements that don't contain readable text
        doc.css("script, style, noscript, iframe, svg").remove

        # Extract text content
        text = doc.text

        # Clean up whitespace (collapse multiple spaces/newlines into single space)
        text = text.gsub(/\s+/, " ").strip

        text.presence
      rescue StandardError => e
        Rails.logger.warn("BookmarkSearch: Failed to extract content from #{@anga.filename}: #{e.message}")
        nil
      end
    end
  end
end
