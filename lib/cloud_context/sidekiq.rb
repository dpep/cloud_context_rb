require 'sidekiq'

module CloudContext
  module Sidekiq
    extend self

    JOB_KEY = 'cloud_context'

    def install
      ::Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.add ClientAdapter
        end
      end

      ::Sidekiq.configure_server do |config|
        # for jobs that enqueue other jobs
        config.client_middleware do |chain|
          chain.add ClientAdapter
        end

        config.server_middleware do |chain|
          chain.add ServerAdapter
        end
      end
    end

    class ClientAdapter
      def call(_, job, *)
        unless CloudContext.empty?
          job[JOB_KEY] = JSON.generate(CloudContext.to_h)
        end

        yield
      end
    end

    class ServerAdapter
      def call(worker, job, *)
        CloudContext.contextualize do
          if job[JOB_KEY]
            CloudContext.update(JSON.load(job.delete(JOB_KEY)))
          end

          yield
        end
      end
    end
  end
end

CloudContext::Sidekiq.install
