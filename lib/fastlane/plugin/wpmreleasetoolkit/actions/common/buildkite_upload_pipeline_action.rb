module Fastlane
  module Actions
    class BuildkiteUploadPipelineAction < Action
      DEFAULT_ENV_FILE = File.join('.buildkite', 'shared-pipeline-vars').freeze
      DEFAULT_COMMIT = 'HEAD'.freeze

      def self.run(params)
        env_file = params[:env_file]
        pipeline_file = params[:pipeline_file]
        branch = params[:branch]
        commit = params[:commit]

        UI.user_error!("Pipeline file not found: #{pipeline_file}") unless File.exist?(pipeline_file)
        UI.user_error!('You should not provide both `branch` and `commit`') if !branch.nil? && commit != 'HEAD'
        UI.user_error!('This action can only be called from a Buildkite CI build') unless ENV['BUILDKITE'] == 'true'

        UI.message "Uploading pipeline on #{pipeline_file}, #{"branch #{branch}, " if branch}commit #{commit}"

        env_vars = {
          'BUILDKITE_BRANCH' => branch,
          'BUILDKITE_COMMIT' => commit
        }.compact

        if env_file && File.exist?(env_file)
          UI.message(" - Sourcing environment file beforehand: #{env_file}")

          sh(env_vars, "source #{env_file.shellescape} && buildkite-agent pipeline upload #{pipeline_file.shellescape}")
        else
          sh(env_vars, 'buildkite-agent', 'pipeline', 'upload', pipeline_file)
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
            key: :branch,
            description: 'The branch you want to run the pipeline on',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :commit,
            description: 'The commit hash you want to run the pipeline on',
            optional: true,
            default_value: DEFAULT_COMMIT,
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
