require 'rails/railtie'

module CloudContext
  module Rails
    extend self

    Adapter = CloudContext::Rack::Adapter

    class Railtie < ::Rails::Railtie
      initializer "cloud_context" do |app|
        # TODO: check for duplicate?
        app.config.middleware.use CloudContext::Rails::Adapter

        # for Rails console `reload!`
        app.reloader.to_complete do
          CloudContext.clear
        end
      end
    end
  end
end
