require 'rack'

module CloudContext
  module Rack
    extend self

    def from_env(env)
      env.each do |key, value|
        # https://datatracker.ietf.org/doc/html/rfc3875#section-4.1.18
        next unless key.start_with?('HTTP_')
        key = key.delete_prefix('HTTP_')

        next unless key.start_with?(CloudContext.http_header_prefix)
        key.delete_prefix!(CloudContext.http_header_prefix)

        CloudContext[key] = value
      end
    end

    class Adapter
      def initialize(app)
        @app = app
      end

      def call(env)
        CloudContext.contextualize do
          CloudContext::Rack.from_env(env)

          @app.call(env)
        end
      end
    end
  end
end
