# == Schema Information
#
# Table name: texts
# Database name: primary
#
#  id            :string(36)       not null, primary key
#  extract_error :text
#  extracted_at  :datetime
#  source_type   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  anga_id       :string(36)       not null
#
# Indexes
#
#  index_texts_on_anga_id  (anga_id) UNIQUE
#
# Foreign Keys
#
#  anga_id  (anga_id => angas.id)
#
FactoryBot.define do
  factory :text do
    anga
    source_type { "bookmark" }

    trait :bookmark do
      source_type { "bookmark" }
    end

    trait :pdf do
      source_type { "pdf" }
    end

    trait :extracted do
      extracted_at { Time.current }

      after(:create) do |text|
        content = text.source_type == "bookmark" ? "# Extracted Content\n\nSample extracted text." : "Extracted PDF text content."
        filename = text.source_type == "bookmark" ? "#{File.basename(text.anga.filename, '.*')}.md" : "#{File.basename(text.anga.filename, '.*')}.txt"
        content_type = text.source_type == "bookmark" ? "text/markdown" : "text/plain"

        text.file.attach(
          io: StringIO.new(content),
          filename: filename,
          content_type: content_type
        )
      end
    end

    trait :failed do
      extract_error { "Failed to extract plaintext" }
    end
  end
end
