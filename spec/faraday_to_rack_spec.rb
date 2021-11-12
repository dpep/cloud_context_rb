describe CloudContext do
  subject { JSON::load(conn.get('/').body) }

  let(:conn) do
    Faraday.new do |builder|
      builder.use CloudContext::Faraday::Adapter
      builder.adapter :rack, rack_app
    end
  end

  let(:rack_app) do
    Rack::Builder.new do
      use Rack::Lint
      use CloudContext::Rack::Adapter

      run (lambda do |env|
        context = JSON.generate(CloudContext.to_h)
        [200, {'Content-Type' => 'application/json'}, [context]]
      end)
    end
  end

  it 'propagates CloudContext' do
    CloudContext['abc'] = '123'

    is_expected.to eq({ 'abc' => '123' })
  end
end
