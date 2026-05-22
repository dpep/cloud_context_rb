require_relative 'lib/cloud_context/version'

Gem::Specification.new do |s|
  s.name        = 'cloud_context'
  s.version     = CloudContext::VERSION
  s.authors     = ['Daniel Pepper']
  s.summary     = 'Propagate request context across distributed systems'
  s.description = <<~DESCRIPTION
    CloudContext is a thread-local key/value store that rides along with
    downstream HTTP requests (via headers) and Sidekiq jobs (via job
    metadata), so request-scoped metadata such as request id, tenant id,
    and user id propagates automatically across service and process
    boundaries. Ships with Rack, Rails, Faraday, Sidekiq, and RSpec
    integrations.
  DESCRIPTION
  s.files       = `git ls-files * ':!:spec'`.split("\n")
  s.homepage    = "https://github.com/dpep/cloud_context_rb"
  s.license     = 'MIT'

  s.required_ruby_version = ">= 3"

  s.add_development_dependency 'base64'
  s.add_development_dependency 'benchmark'
  s.add_development_dependency 'bigdecimal'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'codecov'
  s.add_development_dependency 'faraday', '~> 2'
  s.add_development_dependency 'faraday-rack'
  s.add_development_dependency 'ice_age'
  s.add_development_dependency 'logger'
  s.add_development_dependency 'mutex_m'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rails', '~> 6'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sidekiq', '~> 7'
  s.add_development_dependency 'simplecov'
end
