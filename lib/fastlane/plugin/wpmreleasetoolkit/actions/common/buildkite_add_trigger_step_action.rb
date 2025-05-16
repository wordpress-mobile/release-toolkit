# frozen_string_literal: true

require 'open3'

module Fastlane
  module Actions
    class BuildkiteAddTriggerStepAction < Action
      def self.run(params)
        # Extract parameters
        pipeline_file = params[:pipeline_file]
        build_name = File.basename(pipeline_file, '.yml')
        message = params[:message] || build_name
        branch = params[:branch] || `git rev-parse --abbrev-ref HEAD`.strip
        environment = params[:environment] || {}
        buildkite_pipeline_slug = params[:buildkite_pipeline_slug]
        async = params[:async]
        label = params[:label] || ":buildkite: Trigger #{build_name} on #{branch}"
        depends_on = params[:depends_on]&.then { |v| v.empty? ? nil : Array(v) }

        # Add the PIPELINE environment variable to the environment hash
        environment = environment.merge('PIPELINE' => pipeline_file)

        # Create the trigger step YAML
        trigger_yaml = {
          'steps' => [
            {
              'trigger' => buildkite_pipeline_slug,
              'label' => label,
              'async' => async,
              'build' => {
                'branch' => branch,
                'message' => message,
                'env' => environment
              },
              'depends_on' => depends_on
            }.compact,
          ]
        }.to_yaml

        # Use buildkite-agent to upload the pipeline
        _stdout, stderr, status = Open3.capture3('buildkite-agent', 'pipeline', 'upload', stdin_data: trigger_yaml)

        # Check for errors
        UI.user_error!("Failed to upload pipeline: #{stderr}") unless status.success?

        # Log success
        UI.success("Added a trigger step to the current Buildkite build to start a new build for #{pipeline_file} on branch #{branch}")
      end

      def self.description
        'Adds a trigger step to the current Buildkite pipeline to start a new build from this one'
      end

      def self.details
        <<~DETAILS
          This action adds a `trigger` step to the current Buildkite build, to start a separate build from the current one.

          This is slightly different to `buildkite-agent pipeline upload`-ing the YAML steps of the build directly to the current build,
            as this approach ensures the triggered build starts from a clean and independant context.
            - This is particularly important if the build being triggered rely on the fact that the current build pushed new commits
              to the Git branch and we want the new build's steps to start from the new commit.
            - This is also necessary for cases where we run builds on a mirror of the original Git repo (e.g. for pipelines of repos hosted
              in a private GitHub Enterprise server, mirrored on GitHub.com for CI building purposes) and we want the new build being triggered
              to initiate a new sync of the Git repo as part of the CI build bootstrap process, to get the latest commits.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :buildkite_pipeline_slug,
            env_name: 'BUILDKITE_PIPELINE_SLUG',
            description: 'The slug of the Buildkite pipeline to trigger. Defaults to the same slug as the current pipeline, so usually not necessary to provide explicitly',
            type: String,
            optional: false # But most likely to be auto-provided by the ENV var of the current build and thus not needed to be provided explicitly
          ),
          FastlaneCore::ConfigItem.new(
            key: :label,
            description: 'Custom label for the trigger step. If not provided, defaults to ":buildkite: Trigger {`pipeline_file`\'s basename} on {branch}"',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :pipeline_file,
            description: 'The path (relative to `.buildkite/`) to the pipeline YAML file to use for the triggered build',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :branch,
            description: 'The branch to trigger the build on. Defaults to the Git branch currently checked out at the time of running the action (which is not necessarily the same as the `BUILDKITE_BRANCH` the current build initially started on)',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :message,
            description: 'The message / title to use for the triggered build. If not provided, defaults to the `pipeline_file`\'s basename',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :environment,
            description: 'Environment variables to pass to the triggered build (in addition to the PIPELINE={pipeline_file} that will be automatically injected)',
            type: Hash,
            default_value: {},
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :async,
            description: 'Whether to trigger the build asynchronously (true) or wait for it to complete (false). Defaults to false',
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :depends_on,
            env_name: 'BUILDKITE_STEP_KEY', # This is the env var that Buildkite sets for the current step
            description: 'The steps to depend on before triggering the build. Defaults to the current step this action is called from, if said step has a `key:` attribute set. Use an empty array to explicitly not depend on any step even if the current step has a `key`',
            type: Array,
            default_value: [],
            optional: true
          ),
        ]
      end

      def self.return_value
        'Returns true if the pipeline was successfully uploaded. Throws a `user_error!` if it failed to upload the `trigger` step to the current build'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          <<~CODE,
            # Use default/inferred values for most parameters
            buildkite_add_trigger_step(
              pipeline_file: "release-build.yml",
              environment: { "RELEASE_VERSION" => "1.2.3" },
            )
          CODE
          <<~CODE,
            # Use custom values for most parameters
            buildkite_add_trigger_step(
              label: "🚀 Trigger Release Build",
              pipeline_file: "release-build.yml",
              branch: "release/1.2.3",
              message: "Release Build (123)",
              environment: { "RELEASE_VERSION" => "1.2.3" },
              async: false,
            )
          CODE
        ]
      end

      def self.category
        :building
      end
    end
  end
end
