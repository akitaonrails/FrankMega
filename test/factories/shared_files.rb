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

    trait :image do
      original_filename { "photo.png" }
      content_type { "image/png" }
    end

    trait :video do
      original_filename { "clip.mp4" }
      content_type { "video/mp4" }
    end

    trait :audio do
      original_filename { "song.mp3" }
      content_type { "audio/mpeg" }
    end
  end
end
