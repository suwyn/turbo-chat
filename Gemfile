# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read('.ruby-version').split('-').last.strip

gem 'rails', '~> 7.0.4'

gem 'activerecord-jdbcsqlite3-adapter'

gem 'puma', '~> 5.0'

gem 'importmap-rails'

gem 'turbo-rails'

gem 'stimulus-rails'

gem 'bootsnap', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem "propshaft", "~> 0.6.4"
gem 'slim', '~> 4.1.0'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]

  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 6.0.0'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'
  gem 'pry', '~> 0.14'
  gem 'pry-rails', '~> 0.3'
  gem "rubocop", "~> 1.43"
  gem "rubocop-rails", "~> 2.17"
  gem "rubocop-rspec", "~> 2.18"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
