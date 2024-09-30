module Fastlane
  module Actions
    class BuildkitePipelineUploadAction < Action
      DEFAULT_ENV_FILE = File.join('.buildkite', 'shared-pipeline-vars').freeze

      def self.run(params)
        pipeline_file = params[:pipeline_file]
        env_file = params[:env_file]
        environment = params[:environment]

        UI.user_error!("Pipeline file not found: #{pipeline_file}") unless File.exist?(pipeline_file)
        UI.user_error!('This action can only be called from a Buildkite CI build') unless ENV['BUILDKITE'] == 'true'

        UI.message "Adding steps from `#{pipeline_file}` to the current build"

        if env_file && File.exist?(env_file)
          UI.message(" - Sourcing environment file beforehand: #{env_file}")

          sh(environment, "source #{env_file.shellescape} && buildkite-agent pipeline upload #{pipeline_file.shellescape}")
        else
          sh(environment, 'buildkite-agent', 'pipeline', 'upload', pipeline_file)
        end
      end

      def self.description
        # https://buildkite.com/docs/agent/v3/cli-pipeline#uploading-pipelines
        'Uploads a pipeline to Buildkite, adding all its steps to the current build'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :pipeline_file,
            description: 'The path to the YAML pipeline file to upload',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :env_file,
            description: 'The path to a bash file to be sourced before uploading the pipeline',
            optional: true,
            default_value: DEFAULT_ENV_FILE,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :environment,
            description: 'Environment variables to load when running `pipeline upload`, to allow for variable substitution in the YAML pipeline',
            type: Hash,
            default_value: {}
          ),
        ]
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
