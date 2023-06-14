module Fastlane
  module Actions
    class BuildkiteTriggerBuildAction < Action
      def self.run(params)
        require 'buildkit'

        UI.message "Triggering build on branch #{params[:branch]}, commit #{params[:commit]}, using pipeline from #{params[:pipeline_file]}"

        pipeline_name = {
          PIPELINE: params[:pipeline_file]
        }
        options = {
          branch: params[:branch],
          commit: params[:commit],
          env: params[:environment].merge(pipeline_name),
          message: params[:message],
          # Buildkite will not trigger a build if the GitHub activity for that branch is turned off
          # We want API triggers to work regardless of the GitHub activity settings, so this option is necessary
          # https://forum.buildkite.community/t/request-build-error-branches-have-been-disabled-for-this-pipeline/1463/2
          ignore_pipeline_branch_filters: true
        }.compact # remove entries with `nil` values from the Hash, if any

        client = Buildkit.new(token: params[:buildkite_token])
        response = client.create_build(
          params[:buildkite_organization],
          params[:buildkite_pipeline],
          options
        )

        if response.state == 'scheduled'
          UI.success("Successfully scheduled new build. You can see it at '#{response.web_url}'")
        else
          UI.crash!("Failed to start job\nError: [#{response}]")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Triggers a job on Buildkite'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :buildkite_token,
            env_names: %w[BUILDKITE_TOKEN BUILDKITE_API_TOKEN],
            description: 'Buildkite Personal Access Token',
            type: String,
            sensitive: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :buildkite_organization,
            env_name: 'BUILDKITE_ORGANIZTION',
            description: 'The Buildkite organization that contains your pipeline',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :buildkite_pipeline,
            env_name: 'BUILDKITE_PIPELINE',
            description: %(The Buildkite pipeline you'd like to build),
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :branch,
            description: 'The branch you want to build',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :commit,
            description: 'The commit hash you want to build',
            type: String,
            default_value: 'HEAD'
          ),
          FastlaneCore::ConfigItem.new(
            key: :message,
            description: 'A custom message to show for the build in Buildkite\'s UI',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :pipeline_file,
            description: 'The name of the pipeline file in the project',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :environment,
            description: 'Any additional environment variables to provide to the job',
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
