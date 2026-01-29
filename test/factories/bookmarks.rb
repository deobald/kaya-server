FactoryBot.define do
  factory :bookmark do
    anga
    url { "https://example.com" }
    cached_at { nil }

    trait :cached do
      cached_at { Time.current }
      after(:create) do |bookmark|
        bookmark.html_file.attach(
          io: StringIO.new("<html><body>Test</body></html>"),
          filename: "index.html",
          content_type: "text/html"
        )
        bookmark.favicon.attach(
          io: StringIO.new("fake-favicon-data"),
          filename: "favicon.ico",
          content_type: "image/x-icon"
        )
      end
    end
  end
end
