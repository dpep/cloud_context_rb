require 'cloud_context/version'

module CloudContext
  extend self

  autoload :Faraday, 'cloud_context/faraday'
  autoload :Rack, 'cloud_context/rack'
  autoload :Rails, 'cloud_context/rails'
  autoload :RSpec, 'cloud_context/rspec'
  autoload :Sidekiq, 'cloud_context/sidekiq'

  def [](key)
    context[normalize_key(key)]
  end

  def []=(key, value)
    if value.nil?
      delete(key)
      nil
    else
      context[normalize_key(key)] = normalize_value(value)
    end
  end

  def clear
    context.clear
  end

  def delete(key)
    context.delete(normalize_key(key))
  end

  def empty?
    context.empty?
  end

  def fetch(key, *args, &block)
    context.fetch(normalize_key(key), *args, &block)
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

  def size
    context.size
  end

  def bytesize
    empty? ? 0 : JSON.generate(context).bytesize
  end

  # config
  attr_reader :http_header

  @http_header = 'X_CLOUD_CONTEXT'
  def http_header=(header)
    @http_header = header.upcase.tr('-', '_')
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
    key.to_s
  end

  def normalize_value(value)
    serialized = JSON.generate(value)
    if JSON.parse(serialized) != value
      raise ArgumentError, "will not be deserialized properly: #{value}"
    end

    value
  rescue JSON::ParserError
    raise ArgumentError, "can not be serialized: #{value}"
  end
end
