source "https://rubygems.org"

## RUBY VERSION
ruby file: ".ruby-version"

## SERVER
gem "puma"

## RAILS
gem "rails", github: "rails/rails", branch: "main"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

## DATABASE
gem "pg"

## ASSETS
gem "importmap-rails"
gem "propshaft"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"

## LIBRARIES
gem "bootsnap", require: false
gem "jbuilder"

group :production do
  gem "airbrake"
  gem "postmark-rails"
end

group :development do
  gem "amazing_print"
  gem "better_errors"
  gem "binding_of_caller"
  # gem "bullet" # disabled until support for Rails 8
  gem "rails_live_reload"
  gem "web-console"
end

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", require: "debug/prelude"
  gem "rubocop-javierav", require: false
end

group :test do
  gem "capybara"
  gem "cuprite"
end
