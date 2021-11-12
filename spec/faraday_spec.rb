describe CloudContext::Faraday do
  subject { JSON::load(conn.get('/').body) }

  let(:conn) do
    Faraday.new do |builder|
      builder.use CloudContext::Faraday::Adapter

      builder.adapter :test do |stub|
        stub.get('/') do |env|
          env.request_headers.delete('User-Agent')

          [
            200,
            { 'Content-Type': 'application/json', },
            JSON.generate(env.request_headers),
          ]
        end
      end
    end
  end

  it 'calls' do
    is_expected.to be_a Hash
    is_expected.to be_empty
  end

  it 'is in the Faraday middleware registry' do
    expect(
      Faraday::Request.lookup_middleware(:cloud_context)
    ).to be CloudContext::Faraday::Adapter

    # create a new connection with the middleware
    expect(
      Faraday.new.request(:cloud_context)
    ).to include CloudContext::Faraday::Adapter
  end

  it 'adds CloudContext headers' do
    CloudContext['abc'] = 123

    is_expected.to eq({ CloudContext.http_header_prefix + 'abc' => 123 })
  end
end
