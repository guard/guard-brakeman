source 'https://rubygems.org'
gemspec

require 'rbconfig'

if RbConfig::CONFIG['target_os'] =~ /darwin/i
  gem 'rb-fsevent', '>= 0.4.0'
  gem 'growl',      '~> 1.0.3'
end
if RbConfig::CONFIG['target_os'] =~ /linux/i
  gem 'rb-inotify', '>= 0.8.4'
  gem 'libnotify',  '~> 0.3.0'
end

group :development, :test do
  gem 'rake'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'rspec'
  gem 'aruba'
end
