require "pdf-reader"

module Search
  class PdfSearch < BaseSearch
    protected

    def extract_content
      return nil unless @anga.file.attached?

      tempfile = Tempfile.new([ "pdf_search", ".pdf" ])
      begin
        tempfile.binmode
        tempfile.write(@anga.file.download)
        tempfile.rewind

        reader = PDF::Reader.new(tempfile.path)
        text = reader.pages.map(&:text).join("\n\n")
        text.presence
      rescue StandardError
        nil
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end
end
