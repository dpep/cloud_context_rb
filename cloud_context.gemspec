require_relative 'lib/cloud_context/version'

Gem::Specification.new do |s|
  s.name        = 'cloud_context'
  s.version     = CloudContext::VERSION
  s.authors     = ['Daniel Pepper']
  s.summary     = 'CloudContext'
  s.description = <<~DESCRIPTION
    Thread-local request context that rides along with downstream
    HTTP and Sidekiq calls via headers, so request-scoped metadata
    (request id, tenant, user) propagates across service boundaries.
  DESCRIPTION
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
