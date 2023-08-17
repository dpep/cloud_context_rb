describe CloudContext::RSpec, :order => :defined do
  subject { CloudContext }

  let(:hooks) do
    RSpec.configuration.hooks.send(:all_hooks_for, :after, :example).select do |hook|
      hook.block == CloudContext::RSpec::Adapter
    end
  end

  context 'with RSpec Adapter enabled' do
    before { described_class.enable }

    it 'has installed a hook' do
      expect(hooks).not_to be_empty
    end

    it 'has only installed one hook' do
      expect(hooks.count).to be 1
    end

    it 'does not matter what we put into CloudContext here' do
      CloudContext['abc'] = 123
    end

    it 'starts with an empty context' do
      is_expected.to be_empty
    end

    it 'clears CloudContext' do
      expect(CloudContext).to receive(:clear)
    end
  end

  context 'with RSpec Adapter disabled' do
    before { described_class.disable }

    it 'still has a hook installed, unfortunately, but it is disabled' do
      expect(hooks).not_to be_empty
    end

    it '*does* matter what we put into CloudContext here' do
      CloudContext['abc'] = 456
    end

    it 'does not end with an empty context' do
      expect { is_expected.to be_empty }.to fail
    end

    it 'does not clear CloudContext' do
      expect(CloudContext).not_to receive(:clear)
    end

    it 'needs to be cleared manually' do
      CloudContext.clear
    end
  end
end
