# encoding: utf-8

Gem::Specification.new do |s|
  s.name        = 'guard-brakeman'
  s.version     = '1.0.0'
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.authors     = ['Neil Matatall', 'Justin Collins']
  s.homepage    = 'https://github.com/guard/guard-brakeman'
  s.summary     = 'Guard gem for Brakeman'
  s.description = 'Guard::Brakeman automatically scans your Rails app for vulnerabilities using the Brakeman scanner: https://github.com/presidentbeef/brakeman'

  s.add_dependency 'guard',   '>= 2.0.0'
  s.add_dependency 'guard-compat', '~> 1.0'
  s.add_dependency 'brakeman', '>= 2.1.1'

  s.files        = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'

  s.rdoc_options = ["--charset=UTF-8", "--main=README.md", "--exclude='(test|spec)|(Gem|Guard|Rake)file'"]
end
