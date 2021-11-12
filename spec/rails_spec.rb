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
    expect(get('/')).to be 200
    JSON.load(response.body)
  end

  it 'renders fine' do
    is_expected.to be_a Hash
  end

  it 'starts empty' do
    is_expected.to be_empty
  end

  it 'inherits the current CloudContext' do
    CloudContext['abc'] = 123

    is_expected.to eq({ 'abc' => 123 })
  end

  it 'resets CloudContext after the request, via middleware' do
    CloudContext['abc'] = 123
    subject

    expect(CloudContext).to be_empty
  end
end
