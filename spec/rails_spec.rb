describe CloudContext::Rails, type: :request do
  # need type request so middleware is used

  describe 'Rails application' do
    let(:app) { Rails.application }

    it 'adds middleware automatically' do
      expect(app.middleware).to include(CloudContext::Rails::Adapter)
    end

    it 'clears CloudContext when Rails is reloaded' do
      CloudContext['abc'] = 123
      expect(CloudContext).not_to be_empty

      app.reloader.reload!
      expect(CloudContext).to be_empty
    end
  end

  subject do
    expect(get('/', params: { context: rails_context })).to be 200
    JSON.load(response.body)
  end

  let(:rails_context) { {} }

  it 'renders fine' do
    is_expected.to be_a Hash
  end

  it 'starts empty' do
    is_expected.to be_empty
  end

  it 'isolates the Rails context from this context' do
    CloudContext['abc'] = 123
    is_expected.to be_empty
    expect(CloudContext.to_h).to eq({ 'abc' => 123 })
  end

  context 'when Rails context updates CloudContext' do
    let(:rails_context) { { 'abc' => '123' } }

    it 'isolates this context from Rails' do
      is_expected.to eq rails_context
      expect(CloudContext).to be_empty
    end
  end
end
