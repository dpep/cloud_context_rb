require 'sidekiq/testing'

Sidekiq::Testing.server_middleware do |chain|
  chain.add CloudContext::Sidekiq::ServerAdapter
end

class HardWorker
  include Sidekiq::Worker

  attr_accessor :expectation

  def perform(*args)
    CloudContext['in_worker'] = true

    expectation&.call(*args)
  end
end

describe CloudContext::Sidekiq do
  before do
    allow(HardWorker).to receive(:new).and_return(worker)
  end

  after do
    HardWorker.drain
  end

  let(:worker) { HardWorker.new }

  # sanity check the test setup
  describe 'HardWorker' do
    it 'calls HardWorker.perform' do
      expect(worker).to receive(:perform)

      HardWorker.perform_async
    end

    it 'calls the expectation proc' do
      worker.expectation = Proc.new do
        RSpec::Expectations.fail_with('counter-example')
      end

      HardWorker.perform_async

      expect {
        HardWorker.drain
      }.to fail
    end

    it 'calls HardWorker.perform with the given args' do
      args = [ 'a', 'b', 'c' ]

      worker.expectation = Proc.new do |*w_args|
        expect(w_args).to eq args
      end

      HardWorker.perform_async(*args)
    end

    it 'sets a CloudContext variable' do
      worker.expectation = Proc.new do
        expect(CloudContext['in_worker']).to be true
      end
    end
  end

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
    it 'propagates CloudContext to Sidekiq jobs' do
      CloudContext['abc'] = 123

      worker.expectation = Proc.new do
        expect(CloudContext.to_h).to include('abc' => 123)
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
      worker.expectation = Proc.new do
        expect(CloudContext.to_h).to eq('in_worker' => true)
      end

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
  end
end
