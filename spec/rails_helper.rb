require 'spec_helper'

require 'action_controller/railtie'
require 'rspec/rails'

class EchoController < ActionController::Base
  def index
    render json: CloudContext.to_h
  end
end

RSpec.configure do |rspec|
  rspec.infer_base_class_for_anonymous_controllers = false

  rspec.before(:example, [:rails, type: :request]) do
    # create a fresh, new Rails app
    Rails.application = Class.new(Rails::Application) do
      config.eager_load = false
      # config.logger = ActiveSupport::Logger.new($stdout)
      config.hosts.clear # disable hostname filtering
    end

    Rails.initialize!

    Rails.application.routes.draw do
      get '/' => 'echo#index'
    end
  end
end
