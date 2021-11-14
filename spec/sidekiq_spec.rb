require 'sidekiq/testing'

Sidekiq::Testing.server_middleware do |chain|
  chain.add CloudContext::Sidekiq::ServerAdapter
end

class HardWorker
  include Sidekiq::Worker

  attr_accessor :expectation

  def perform
    CloudContext['in_worker'] = true

    expectation&.call
  end
end

describe CloudContext::Sidekiq do
  before do
    allow(HardWorker).to receive(:new).and_return(worker)
  end

  after do
    CloudContext.clear
    HardWorker.drain
  end

  let(:worker) { HardWorker.new }

  describe '.install' do
    it 'loads Sidekiq middleware' do
      expect(Sidekiq.client_middleware.map(&:klass)).to include(
        CloudContext::Sidekiq::ClientAdapter
      )
      expect(Sidekiq::Testing.server_middleware.map(&:klass)).to include(
        CloudContext::Sidekiq::ServerAdapter
      )
    end
  end

  describe 'Sidekiq middleware' do
    before do
      # sanity check
      expect(worker).to receive(:perform).and_call_original
    end

    it 'propagates CloudContext to Sidekiq jobs' do
      CloudContext['abc'] = 123

      worker.expectation = Proc.new do
        expect(CloudContext.to_h).to eq('abc' => 123, 'in_worker' => true)
      end

      HardWorker.perform_async
    end

    it 'isolates the Sidekiq worker context from this one' do
      CloudContext['abc'] = 123
      HardWorker.perform_async
      CloudContext.clear

      worker.expectation = Proc.new do
        expect(CloudContext.to_h).to include('abc' => 123)
      end

      expect(HardWorker.jobs.count).to be 1
    end

    it 'isolates this context from the Sidekiq worker' do
      Sidekiq::Testing.inline! do
        HardWorker.perform_async
      end

      expect(HardWorker.jobs).to be_empty
      expect(CloudContext).to be_empty
    end

    it 'serializes CloudContext as a job sidekiq_option' do
      CloudContext['abc'] = 123
      HardWorker.perform_async

      expect(HardWorker.jobs[0]).to include(CloudContext::Sidekiq::JOB_KEY)
    end

    it 'does not serialize an empty CloudContext' do
      HardWorker.perform_async

      expect(HardWorker.jobs[0]).not_to include(CloudContext::Sidekiq::JOB_KEY)
    end

    # sanity check the test setup
    describe 'HardWorker' do
      it 'calls the expectation proc' do
        HardWorker.perform_async

        worker.expectation = Proc.new do
          RSpec::Expectations.fail_with('counter-example')
        end

        expect {
          HardWorker.drain
        }.to fail
      end
    end
  end
end
