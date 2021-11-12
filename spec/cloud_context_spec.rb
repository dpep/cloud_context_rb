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

  describe '.normalize_keys' do
    subject { CloudContext.to_h.keys }

    def normalize(key, normalized)
      CloudContext[key] = 123
      expect(CloudContext.to_h.count).to eq 1
      expect(CloudContext.to_h.keys.first).to eq(normalized)
      CloudContext.clear
    end

    it 'normalizes keys' do
      normalize 'abc', 'abc'
      normalize 'ABc', 'abc'
      normalize 'a b c', 'a_b_c'
      normalize 'a-B-c', 'a_b_c'
      normalize 'a#b$c', 'a_b_c'
      normalize 'a 2 c', 'a_2_c'
      normalize 'a . c', 'a___c'
    end
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
