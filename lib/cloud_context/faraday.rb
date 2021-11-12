require 'faraday'

module CloudContext
  module Faraday
    extend self

    class Adapter < ::Faraday::Middleware
      def on_request(env)
        CloudContext.to_h.each do |key, value|
          env[:request_headers][CloudContext.http_header_prefix + key] = value
        end
      end
    end
  end
end

Faraday::Request.register_middleware(
  cloud_context: -> { CloudContext::Faraday::Adapter },
)

# header formats
# https://github.com/lostisland/faraday_middleware/blob/main/lib/faraday_middleware/rack_compatible.rb
