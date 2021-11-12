require 'rack'

module CloudContext
  module Rack
    extend self

    def from_env(env)
      context = env["HTTP_#{CloudContext.http_header}"]
      return unless context

      CloudContext.update(JSON.load(context))
    rescue JSON::ParserError
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
