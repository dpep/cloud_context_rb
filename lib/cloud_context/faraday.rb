require 'faraday'

module CloudContext
  module Faraday
    extend self

    class Adapter < ::Faraday::Middleware
      def on_request(env)
        data = options[:context]&.call || CloudContext.to_h
        return if data.empty?

        header = options[:header]&.upcase&.tr('-', '_') || CloudContext.http_header

        env[:request_headers][header] = JSON.generate(data)
      end
    end
  end
end

Faraday::Middleware.register_middleware(
  cloud_context: -> { CloudContext::Faraday::Adapter },
)
