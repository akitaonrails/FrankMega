require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  # Coverage thresholds disabled during parallel tests; enforce in CI
  # minimum_coverage 90
  # minimum_coverage_by_file 80
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/vendor/"

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Helpers", "app/helpers"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
