require 'rspec/core'

module CloudContext
  module RSpec
    extend self

    attr_reader :enabled

    Adapter = ->(*) { CloudContext::RSpec.enabled ? CloudContext.clear : nil }

    def enable
      if @enabled.nil?
        # only add once

        ::RSpec.configure do |config|
          config.after &CloudContext::RSpec::Adapter
        end
      end

      @enabled = true
    end

    def disable
      @enabled = false
    end
  end
end
