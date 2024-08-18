require "./lib/cloud_context/version"

package = CloudContext


Gem::Specification.new do |s|
  s.name        = File.basename(__FILE__, ".gemspec")
  s.version     = package.const_get('VERSION')
  s.authors     = ['Daniel Pepper']
  s.summary     = package.to_s
  s.description = '...'
  s.files       = `git ls-files * ':!:spec'`.split("\n")
  s.homepage    = "https://github.com/dpep/cloud_context_rb"
  s.license     = 'MIT'

  s.required_ruby_version = ">= 3"

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'codecov'
  s.add_development_dependency 'faraday', '~> 1'
  s.add_development_dependency 'ice_age'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rails', '~> 6'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sidekiq', '~> 7'
  s.add_development_dependency 'simplecov'
end
