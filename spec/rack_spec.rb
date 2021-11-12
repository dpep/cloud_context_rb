describe CloudContext::Rack do
  describe '#call' do
    subject { CloudContext::Rack::Adapter.new(app).call(env) }

    let(:app) { ->(*) {} }
    let(:env) {
      # use Rack::Test to normalize headers
      Rack::MockRequest.env_for('/', current_session.send(:headers_for_env))
    }

    it 'yields to the app' do
      expect(app).to receive(:call).with(env)
      subject
    end

    it 'returns a proper rack response' do
      expect(app).to receive(:call) do
        [200, {'Content-Type' => 'text/plain'}, ['OK']]
      end

      Rack::Lint.new(CloudContext::Rack::Adapter.new(app)).call(env)
    end

    context 'when CloudContext headers are set' do
      before do
        header 'X-CC-ABC', '123'
        header 'X-CC-FOO', 'bar'
      end

      it 'initializes CloudContext' do
        expect(app).to receive(:call) do
          expect(CloudContext['abc']).to eq '123'
          expect(CloudContext['foo']).to eq 'bar'
        end

        subject
      end
    end

    it 'isolates the Rack contxt' do
      CloudContext['abc'] = 123

      expect(app).to receive(:call) do
        expect(CloudContext).to be_empty

        CloudContext['xyz'] = '999'
      end

      subject

      expect(CloudContext.to_h).to eq({ 'abc' => 123 })
    end
  end

  context 'as Rack middleware' do
    before { app.use CloudContext::Rack::Adapter }

    let(:app) do
      Rack::Builder.new do
        use Rack::Lint

        run (lambda do |env|
          context = JSON.dump(CloudContext.to_h)
          [200, {'Content-Type' => 'application/json'}, [context]]
        end)
      end
    end
    let(:response) { JSON::load(get('/').body) }

    it 'returns the context' do
      expect(response).to be_a Hash
      expect(response).to be_empty
    end

    it 'parses the headers correctly' do
      header CloudContext.http_header_prefix + 'abc', '123'
      header CloudContext.http_header_prefix + 'foo', 'bar'

      expect(response).to eq({ 'abc' => '123', 'foo' => 'bar' })
    end

    it 'resets between requests' do
      header CloudContext.http_header_prefix + 'abc', '123'
      expect(response).to eq({ 'abc' => '123' })

      with_session('without header') do
        expect(JSON::load(get('/').body)).to be_empty
      end
    end
  end
end
