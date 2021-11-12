require "cloud_context/version"

module CloudContext
  extend self

  autoload :Faraday, "cloud_context/faraday"
  autoload :Rack, "cloud_context/rack"
  autoload :Rails, "cloud_context/rails"
  autoload :RSpec, "cloud_context/rspec"

  def [](key)
    context[normalize_key(key)]
  end

  def []=(key, value)
    context[normalize_key(key)] = normalize_value(value)
  end

  def clear
    context.clear
  end

  def empty?
    context.empty?
  end

  def fetch(key, *args, &block)
    normalize_value(
      context.fetch(normalize_key(key), *args, &block)
    )
  end

  def to_h
    context.dup
  end

  def update(*hashes)
    hashes.each do |hash|
      hash.each do |key, value|
        # normalize
        self[key] = value
      end
    end
  end

  # config
  attr_reader :http_header_prefix

  @http_header_prefix = 'X_CC_'
  def http_header_prefix=(prefix)
    @http_header_prefix = prefix.upcase.tr('-', '_')
  end

  def contextualize(&block)
    context # ensure context is initialized
    Thread.current[:cloud_context].push({})[-1]

    yield
  ensure
    Thread.current[:cloud_context].pop
  end

  private

  def context
    Thread.current[:cloud_context] ||= [{}]
    Thread.current[:cloud_context][-1]
  end

  def normalize_key(key)
    key.to_s.downcase.gsub(/[^A-Za-z0-9_]/, '_')
  end

  def normalize_value(value)
    # value.to_s
    value
  end
end
