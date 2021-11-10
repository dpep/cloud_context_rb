require "cloud_context/version"

module CloudContext
  extend self

  autoload :Rack, "cloud_context/rack"
  autoload :RSpec, "cloud_context/rspec"
  # autoload :Railtie, "cloud_context/railtie"

  def [](key)
    context[normalize_key(key)]
  end

  def []=(key, value)
    context[normalize_key(key)] = normalize_value(value)
  end

  def empty?
    context.empty?
  end

  def fetch(key, *args, &block)
    normalize_value(
      context.fetch(normalize_key(key), *args, &block)
    )
  end

  def clear
    Thread.current[:cloud_context] = nil
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

  private

  def context
    Thread.current[:cloud_context] ||= {}
  end

  def normalize_key(key)
    key.to_s.downcase.tr('-','_')
  end

  def normalize_value(value)
    # value.to_s
    value
  end
end
