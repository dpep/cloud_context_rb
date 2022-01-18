describe CloudContext do
  after { CloudContext.clear }

  describe '.[]' do
    it 'gets values' do
      CloudContext['abc'] = 123
      expect(CloudContext['abc']).to eq 123
    end

    it 'stringifies keys' do
      CloudContext[:abc] = 123
      expect(CloudContext[:abc]).to eq 123
      expect(CloudContext['abc']).to eq 123

      CloudContext[123] = 456
      expect(CloudContext[123]).to eq 456
      expect(CloudContext['123']).to eq 456
    end
  end

  describe '.[]=' do
    it 'deletes keys set to nil' do
      CloudContext['abc'] = 123
      expect(CloudContext['abc']).to eq 123

      CloudContext['abc'] = nil
      expect(CloudContext).to be_empty
    end

    it 'returns the assigned value' do
      expect(CloudContext['abc'] = 123).to eq 123
      expect(CloudContext['abc'] = nil).to eq nil
    end

    it 'ensures value can be serialized and deserialized' do
      expect {
        CloudContext['abc'] = :abc
      }.to raise_error(ArgumentError)

      expect {
        CloudContext['abc'] = Time.now
      }.to raise_error(ArgumentError)
    end
  end

  describe '.delete' do
    it 'removes a key' do
      CloudContext['abc'] = 123
      expect(CloudContext['abc']).to eq 123

      CloudContext.delete('abc')
      expect(CloudContext).to be_empty
    end
  end

  describe '.http_header' do
    subject { described_class.http_header }

    it 'has a default value' do
      is_expected.to be_a String
      is_expected.not_to be_empty
    end

    it 'can be updated' do
      described_class.http_header = 'CC_'
      is_expected.to eq 'CC_'
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
      CloudContext.update(abc: 123)
      expect(CloudContext.to_h).to eq({ 'abc' => 123 })
    end

    it 'accepts many inputs, like Hash#update' do
      CloudContext.update({ abc: 123 }, { foo: 'bar' })
      expect(CloudContext['abc']).to eq 123
      expect(CloudContext['foo']).to eq 'bar'
    end
  end

  describe '.contextualize' do
    it 'isolates two contexts' do
      CloudContext['abc'] = 123
      expect(CloudContext.to_h).to eq({ 'abc' => 123 })

      CloudContext.contextualize do
        expect(CloudContext).to be_empty
        CloudContext['foo'] = 'bar'
        expect(CloudContext.to_h).to eq({ 'foo' => 'bar' })
      end

      expect(CloudContext.to_h).to eq({ 'abc' => 123 })
    end

    it 'ensures against exceptions' do
      CloudContext['abc'] = 123

      expect {
        CloudContext.contextualize do
          CloudContext['foo'] = 'bar'
          raise IOError, 'oh no!'
        end
      }.to raise_error(IOError)

      expect(CloudContext.to_h).to eq({ 'abc' => 123 })
    end
  end

  describe '.size' do
    it { expect(described_class.size).to be 0 }

    it 'tracks each key added' do
      CloudContext['a'] = 1
      expect(described_class.size).to be 1
      CloudContext['b'] = 2
      expect(described_class.size).to be 2
      CloudContext['c'] = 3
      expect(described_class.size).to be 3
    end

    it 'tracks keys deleted' do
      CloudContext['a'] = 1
      expect(described_class.size).to be 1

      CloudContext.delete('a')
      expect(described_class.size).to be 0
    end
  end

  describe '.bytesize' do
    subject { described_class.bytesize }

    it { is_expected.to be 2 }

    it 'increases with key and value size' do
      CloudContext['a'] = 1

      is_expected.to be 7
    end

    it 'is bigger with bigger keys' do
      CloudContext['abc'] = 1

      is_expected.to be 9
    end

    it 'is bigger with string values' do
      CloudContext['abc'] = '1'

      is_expected.to be 11
    end

    it 'is bigger with bigger values' do
      CloudContext['abc'] = '123'

      is_expected.to be 13
    end
  end
end
