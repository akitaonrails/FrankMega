FactoryBot.define do
  factory :shared_file do
    association :user
    max_downloads { 5 }
    download_count { 0 }
    ttl_hours { 24 }
    original_filename { "test_file.pdf" }
    content_type { "application/pdf" }
    file_size { 1024 }

    after(:build) do |shared_file|
      shared_file.file.attach(
        io: StringIO.new("test content"),
        filename: shared_file.original_filename,
        content_type: shared_file.content_type
      )
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :exhausted do
      download_count { 5 }
      max_downloads { 5 }
    end

    trait :large do
      file_size { 500.megabytes }
    end
  end
end
