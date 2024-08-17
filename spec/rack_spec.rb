describe CloudContext::Rack do
  describe '#call' do
    subject do
      header CloudContext.http_header, JSON.generate(CloudContext.to_h)

      # use rack-test to normalize headers
      headers = current_session.instance_variable_get(:@env)
      env = Rack::MockRequest.env_for('/', headers)

      CloudContext::Rack::Adapter.new(app).call(env)
    end

    let(:app) { ->(*) {} }

    it 'yields to the app' do
      expect(app).to receive(:call)
      subject
    end

    it 'returns a proper rack response' do
      expect(app).to receive(:call) do
        [200, {'Content-Type' => 'text/plain'}, ['OK']]
      end

      env = Rack::MockRequest.env_for('/')
      Rack::Lint.new(CloudContext::Rack::Adapter.new(app)).call(env)
    end

    it 'propogates this context into Rack' do
      CloudContext['abc'] = 123
      CloudContext['foo'] = 'bar'

      expect(app).to receive(:call) do
        expect(CloudContext['abc']).to eq 123
        expect(CloudContext['foo']).to eq 'bar'
      end

      subject
    end

    it 'isolates this context from Rack' do
      CloudContext['abc'] = 123

      expect(app).to receive(:call) do
        CloudContext.delete('abc')
        CloudContext['xyz'] = '999'
      end

      subject

      expect(CloudContext.to_h).to eq({ 'abc' => 123 })
    end

    it 'isolates Rack from this context' do
      CloudContext['abc'] = 123

      expect(app).to receive(:call) do
        expect(CloudContext).to be_empty
      end

      CloudContext::Rack::Adapter.new(app).call({})
    end
  end

  context 'as Rack middleware' do
    subject do
      header CloudContext.http_header, JSON.generate(CloudContext.to_h)
      JSON::load(get('/').body)
    end

    let(:app) do
      Rack::Builder.new do
        use Rack::Lint
        use CloudContext::Rack::Adapter

        run (lambda do |env|
          context = JSON.generate(CloudContext.to_h)
          [200, {'Content-Type' => 'application/json'}, [context]]
        end)
      end
    end

    it 'returns the context' do
      is_expected.to be_a Hash
      is_expected.to be_empty
    end

    it 'parses the headers correctly' do
      CloudContext['abc'] = '123'
      CloudContext['foo'] = 'bar'

      is_expected.to eq({ 'abc' => '123', 'foo' => 'bar' })
    end

    it 'resets between requests' do
      CloudContext['abc'] = '123'
      is_expected.to eq({ 'abc' => '123' })

      with_session('without header') do
        expect(JSON::load(get('/').body)).to be_empty
      end
    end
  end
end
