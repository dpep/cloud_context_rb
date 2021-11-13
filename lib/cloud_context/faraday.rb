require 'faraday'

module CloudContext
  module Faraday
    extend self

    class Adapter < ::Faraday::Middleware
      def on_request(env)
        return if CloudContext.empty?

        context = JSON.generate(CloudContext.to_h)
        env[:request_headers][CloudContext.http_header] = context
      end
    end
  end
end

Faraday::Request.register_middleware(
  cloud_context: -> { CloudContext::Faraday::Adapter },
)
