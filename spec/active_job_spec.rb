require 'active_job'
require 'sidekiq/testing'
require 'cloud_context/sidekiq'

class CloudContextActiveJob < ActiveJob::Base
  cattr_accessor :captured_context, :expectation

  def perform(*args)
    self.class.captured_context = CloudContext.to_h
    CloudContext['in_job'] = true

    self.class.expectation&.call(*args)
  end
end

describe CloudContext::ActiveJob do
  before do
    CloudContextActiveJob.captured_context = nil
    CloudContextActiveJob.expectation = nil
  end

  describe '.install' do
    it 'prepends Adapter onto ActiveJob::Base' do
      expect(::ActiveJob::Base.ancestors).to include(described_class::Adapter)
    end
  end

  describe 'serialize' do
    let(:job) { CloudContextActiveJob.new }

    it 'omits the cloud_context key when context is empty' do
      expect(job.serialize).not_to include(described_class::JOB_KEY)
    end

    it 'includes the cloud_context key when context has data' do
      CloudContext['abc'] = 123

      expect(job.serialize).to include(
        described_class::JOB_KEY => '{"abc":123}'
      )
    end
  end

  context 'with inline queue adapter' do
    # the inline adapter performs a full serialize -> execute round trip
    before { ActiveJob::Base.queue_adapter = :inline }

    it 'propagates CloudContext from enqueue to perform' do
      CloudContext['abc'] = 123
      CloudContext['foo'] = 'bar'

      CloudContextActiveJob.perform_later

      expect(CloudContextActiveJob.captured_context).to eq(
        'abc' => 123, 'foo' => 'bar'
      )
    end

    it 'starts with an empty context when nothing was set' do
      CloudContextActiveJob.perform_later

      expect(CloudContextActiveJob.captured_context).to be_empty
    end

    it 'isolates the job context from the enqueuer (no leak out)' do
      CloudContext['abc'] = 123

      CloudContextActiveJob.perform_later

      expect(CloudContext.to_h).to eq('abc' => 123)
      expect(CloudContext['in_job']).to be nil
    end

    it 'isolates the enqueuer context from the job (no leak in)' do
      CloudContext['abc'] = 123

      CloudContextActiveJob.expectation = Proc.new do
        # the job sees the propagated context, plus its own mutations,
        # but it is a separate frame
        CloudContext.delete('abc')
        CloudContext['only_in_job'] = true
      end

      CloudContextActiveJob.perform_later

      expect(CloudContext.to_h).to eq('abc' => 123)
    end

    it 'propagates the inner context when a job enqueues another job' do
      CloudContext['outer'] = 1

      CloudContextActiveJob.expectation = Proc.new do |depth|
        if depth == 0
          CloudContext['inner'] = 2
          CloudContextActiveJob.perform_later(1)
        end
      end

      CloudContextActiveJob.perform_later(0)

      # the second invocation overwrote captured_context, and it must
      # carry the value that the first job set
      expect(CloudContextActiveJob.captured_context).to include(
        'outer' => 1, 'inner' => 2
      )
    end
  end

  context 'with test queue adapter' do
    before { ActiveJob::Base.queue_adapter = :test }
    after { ActiveJob::Base.queue_adapter.enqueued_jobs.clear }

    it 'serializes CloudContext into the job payload' do
      CloudContext['abc'] = 123

      CloudContextActiveJob.perform_later

      payload = ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(payload).to include(described_class::JOB_KEY => '{"abc":123}')
    end

    it 'does not include the key when the context is empty' do
      CloudContextActiveJob.perform_later

      payload = ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(payload).not_to include(described_class::JOB_KEY)
    end
  end

  context 'on Sidekiq' do
    # the corner case: AJ-on-Sidekiq must not double-serialize the
    # context (once into the AJ payload, once into the Sidekiq job hash)
    before { ActiveJob::Base.queue_adapter = :sidekiq }
    after { Sidekiq::Worker.clear_all }

    it 'serializes context into the ActiveJob payload, not the Sidekiq job' do
      CloudContext['abc'] = 123

      CloudContextActiveJob.perform_later

      sidekiq_job = ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper.jobs.first
      expect(sidekiq_job).not_to be_nil

      # Sidekiq sees the AJ wrapper class
      expect(sidekiq_job['class']).to eq(
        CloudContext::Sidekiq::ACTIVE_JOB_WRAPPER
      )

      # context is NOT duplicated at the Sidekiq layer
      expect(sidekiq_job).not_to include(CloudContext::Sidekiq::JOB_KEY)

      # but it IS present inside the serialized AJ payload (args[0])
      aj_payload = sidekiq_job['args'].first
      expect(aj_payload).to include(
        described_class::JOB_KEY => '{"abc":123}'
      )
    end

    it 'propagates context end-to-end through AJ-on-Sidekiq' do
      CloudContext['abc'] = 123

      Sidekiq::Testing.inline! do
        CloudContextActiveJob.perform_later
      end

      expect(CloudContextActiveJob.captured_context).to eq('abc' => 123)
    end

    it 'isolates job context from enqueuer in inline mode' do
      CloudContext['abc'] = 123

      Sidekiq::Testing.inline! do
        CloudContextActiveJob.perform_later
      end

      # job mutation (in_job = true) must not leak back
      expect(CloudContext.to_h).to eq('abc' => 123)
    end

    it 'still propagates for direct Sidekiq workers (non-AJ)' do
      # a direct Sidekiq::Worker bypasses ActiveJob entirely and must
      # continue to use the Sidekiq-layer JOB_KEY
      worker_class = Class.new do
        include Sidekiq::Worker
        def self.name; 'DirectWorker'; end
        def perform; end
      end
      stub_const('DirectWorker', worker_class)

      CloudContext['abc'] = 123

      DirectWorker.perform_async

      sidekiq_job = DirectWorker.jobs.first
      expect(sidekiq_job).to include(CloudContext::Sidekiq::JOB_KEY)
      expect(sidekiq_job['class']).to eq('DirectWorker')
    end
  end
end
