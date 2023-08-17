describe CloudContext::Faraday do
  subject { JSON.load(response[header]) }

  let(:header) { CloudContext.http_header }
  let(:response) { JSON::load(conn.get('/').body) }

  let(:conn) do
    Faraday.new do |builder|
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

  specify 'the base case works' do
    expect(response).to be_a Hash
    expect(response).to be_empty

    is_expected.to be nil
  end

  describe CloudContext::Faraday::Adapter do
    it 'is in the Faraday middleware registry' do
      expect(
        Faraday::Middleware.lookup_middleware(:cloud_context)
      ).to be described_class
    end

    it 'can be added to Faraday connections via symbol' do
      conn = Faraday.new { |f| f.use :cloud_context }

      expect(
        conn.builder.handlers
      ).to include described_class
    end
  end

  context 'with default adapter' do
    before { conn.builder.use CloudContext::Faraday::Adapter }

    it 'adds CloudContext header' do
      CloudContext['abc'] = 123

      expect(response).to include CloudContext.http_header
    end

    it 'serializes and sends CloudContext' do
      CloudContext['abc'] = 123

      is_expected.to eq({ 'abc' => 123 })
    end

    it 'excludes CloudContext header when no context data' do
      expect(CloudContext.to_h).to be_empty
      expect(response).not_to include CloudContext.http_header
    end
  end

  context 'with custom header' do
    let(:header) { 'CONTEXT' }

    before do
      conn.builder.use :cloud_context, header: header
    end

    it 'adds CloudContext header' do
      CloudContext['abc'] = 123

      expect(response).not_to include CloudContext.http_header
      expect(response).to include header
    end

    it 'sends CloudContext' do
      CloudContext['abc'] = 123

      is_expected.to eq({ 'abc' => 123 })
    end
  end

  context 'with custom context' do
    let(:context) { { 'abc' => 456 } }

    before do
      conn.builder.use :cloud_context, context: ->{ context }
    end

    it 'sends context' do
      is_expected.to eq({ 'abc' => 456 })
    end
  end
end
