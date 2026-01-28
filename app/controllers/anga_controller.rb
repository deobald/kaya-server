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
      render json: { success: true, filename: filename }, status: :created
    else
      render json: { error: anga.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
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
