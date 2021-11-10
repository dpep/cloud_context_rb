describe CloudContext do
  after { CloudContext.clear }

  describe '.[]' do
    it 'gets and sets values' do
      CloudContext['abc'] = 123
      expect(CloudContext['abc']).to eq 123
    end

    it 'normalizes keys' do
      CloudContext['abc'] = 123
      expect(CloudContext['abc']).to eq 123
      expect(CloudContext['ABC']).to eq 123
      expect(CloudContext[:abc]).to eq 123
    end

    # it 'normalizes values' do

    # end
  end

  describe '.empty?' do
    it { is_expected.to be_empty }

    it 'works for counter examples' do
      CloudContext['abc'] = 123

      is_expected.not_to be_empty
    end
  end

  describe '.clear' do
    before { CloudContext['abc'] = 123 }

    it 'clears all values' do
      CloudContext.clear
      is_expected.to be_empty
    end
  end

  describe '.update' do
    it 'updates the context' do
      CloudContext.update('abc' => 123)
      expect(CloudContext['abc']).to eq 123
    end

    it 'normalizes the keys' do
      CloudContext.update(ABC: 123)
      expect(CloudContext.to_h).to eq({ 'abc' => 123 })
    end

    it 'accepts many inputs, like Hash#update' do
      CloudContext.update({ abc: 123 }, { foo: 'bar' })
      expect(CloudContext['abc']).to eq 123
      expect(CloudContext['foo']).to eq 'bar'
    end
  end
end
