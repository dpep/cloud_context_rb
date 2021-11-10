require 'rack'

module CloudContext
  module Rack
    extend self

    attr_reader :header_prefix

    @header_prefix = 'X_CC_'
    def header_prefix=(prefix)
      @header_prefix = prefix.upcase.tr('-', '_')
    end

    def from_env(env)
      env.each do |key, value|
        # https://datatracker.ietf.org/doc/html/rfc3875#section-4.1.18
        next unless key.start_with?('HTTP_')
        key = key.delete_prefix('HTTP_')

        next unless key.start_with?(header_prefix)
        key.delete_prefix!(header_prefix)

        CloudContext[key] = value
      end
    end

    class Adapter
      def initialize(app)
        @app = app
      end

      def call(env)
        CloudContext::Rack.from_env(env)

        @app.call(env)
      ensure
        CloudContext.clear
      end
    end
  end
end
