source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Ruby version
ruby '3.1.3'

# Rails version
gem 'rails', '~> 7.0.4'

# Core Gems
gem 'puma', '~> 5.0' # Puma acts as the web server
gem 'sprockets-rails' # Sprockets-Rails is used for compiling and serving web assets
gem 'jbuilder' # JBuilder is used for building JSON APIs
gem 'tzinfo-data' # tzinfo-data provides daylight savings time data
gem 'bootsnap', require: false # Bootsnap speeds up boot times by caching expensive operations

# JavaScript and CSS Bundling
gem 'jsbundling-rails' # JSBundling for JavaScript bundling
gem 'cssbundling-rails' # CSSBundling for CSS bundling

# Hotwire Gems
gem 'turbo-rails' # Turbo enhances navigation by making it faster
gem 'stimulus-rails' # Stimulus is a JavaScript framework

# Authentication
gem 'devise', '~> 4.8' # Devise for authentication
gem 'devise-i18n' # Internationalization (i18n) for Devise

# Search
gem 'ransack', '~> 3.2' # Ransack provides a simple search API

# Pagination
gem 'will_paginate' # WillPaginate for pagination

# Miscellaneous Gems
gem 'ruby-lsp', '~> 0.0.3', :group => :development # Ruby-LSP for Language Server Protocol support
gem 'yard', '~> 0.9.28' # YARD for documentation generation
gem 'hashid-rails', '~> 1.4' # Hashid-Rails for generating unique IDs
gem 'rails_12factor', '~> 0.0.3' # Rails 12factor for making Rails more compatible with 12 factor apps
gem 'i18n_generators' # I18nGenerators for generating localization files

# Capistrano Gems
gem 'capistrano' # Capistrano for deployment
gem 'capistrano-rails' # Capistrano-Rails for Rails deployment
gem 'capistrano-rbenv' # Capistrano-Rbenv for rbenv support
gem 'capistrano-passenger' # Capistrano-Passenger for Passenger support

# Production Gems
group :production do
  gem 'pg' # PG for the database
end
# Development and Test Gems
group :development, :test do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ] # Debug for debugging
  gem 'byebug', '~> 11.1' # Byebug for debugging
  gem 'sqlite3', '~> 1.4' # SQLite3 for the database
  gem 'rubocop' # Rubocop for Ruby code linting
end

group :development do
  gem 'web-console' # Web-Console for displaying a console in the browser
end

group :test do
  gem 'capybara' # Capybara for integration testing
  gem 'selenium-webdriver' # Selenium-Webdriver for browser-based testing
  gem 'webdrivers' # Webdrivers for managing webdrivers needed for testing
end
