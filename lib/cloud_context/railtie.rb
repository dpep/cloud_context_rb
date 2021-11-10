require "rails/railtie"

module CloudContext
  class Railtie < ::Rails::Railtie
    initializer "cloud_context" do |app|
      if defined?(ActionDispatch)
        app.config.middleware.insert_after ActionDispatch::RequestId, CloudContext::Rack::Adapter
      else
        app.config.middleware.insert_after Rack::MethodOverride, CloudContext::Rack::Adapter
      end

      defined?(ActiveSupport) && ActiveSupport::Reloader.to_complete do
        CloudContext.clear!
      end
    end
  end
end
