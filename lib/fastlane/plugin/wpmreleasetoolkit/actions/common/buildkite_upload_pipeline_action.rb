module Fastlane
  module Actions
    class BuildkiteUploadPipelineAction < Action
      def self.run(params)
        env_file = params[:env_file]
        pipeline_file = params[:pipeline_file]
        branch = params[:branch]
        commit = params[:commit]

        UI.user_error!("Pipeline file not found: #{pipeline_file}") unless File.exist?(pipeline_file)

        UI.message "Uploading pipeline #{pipeline_file} on branch #{branch}, commit #{commit}"

        ENV['BUILDKITE_BRANCH'] = branch
        ENV['BUILDKITE_COMMIT'] = commit

        if env_file && File.exist?(env_file)
          UI.message("Sourcing environment file: #{env_file}")

          sh(". #{env_file} && buildkite-agent pipeline upload #{pipeline_file}")
        else
          sh('buildkite-agent', 'pipeline', 'upload', pipeline_file)
        end
      end

      def self.description
        # https://buildkite.com/docs/agent/v3/cli-pipeline#uploading-pipelines
        'Uploads a pipeline to Buildkite, adding all its steps to the current build'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :env_file,
            description: 'The path to the environment variables file to be sourced before uploading the pipeline',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :pipeline_file,
            description: 'The path to the Buildkite pipeline file',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :branch,
            description: 'The branch you want to run the pipeline on',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :commit,
            description: 'The commit hash you want to run the pipeline on',
            optional: true,
            default_value: 'HEAD',
            type: String
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
