require 'rails'

describe CloudContext::Railtie do
  subject { Rails.initialize! }

  before do
    Rails.application = Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
    end
  end

  it 'adds middleware automatically' do
    expect(subject.middleware).to include(CloudContext::Rack::Adapter)
  end
end
