require 'active_job'

module CloudContext
  module ActiveJob
    extend self

    JOB_KEY = 'cloud_context'

    def install
      ::ActiveJob::Base.prepend(Adapter)
    end

    module Adapter
      def serialize
        data = super
        data[JOB_KEY] = JSON.generate(CloudContext.to_h) unless CloudContext.empty?
        data
      end

      def deserialize(job_data)
        @cloud_context = job_data[JOB_KEY]
        super
      end

      def perform_now
        CloudContext.contextualize do
          CloudContext.update(JSON.parse(@cloud_context)) if @cloud_context
          super
        end
      end
    end
  end
end

CloudContext::ActiveJob.install
