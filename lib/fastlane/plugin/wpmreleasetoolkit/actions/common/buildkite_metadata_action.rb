module Fastlane
  module Actions
    class BuildkiteMetadataAction < Action
      def self.run(params)
        # Set/Add new metadata values
        params[:set]&.each do |key, value|
          sh('buildkite-agent', 'meta-data', 'set', key.to_s, value.to_s)
        end

        # Return value of existing metadata key
        sh('buildkite-agent', 'meta-data', 'get', params[:get].to_s) unless params[:get].nil?
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Set/Get metadata to the current Buildkite build'
      end

      def self.details
        <<~DETAILS
          Set and/or get metadata to the current Buildkite build.

          Has to be run on a CI job (where a `buildkite-agent` is running), e.g. typically by a lane
          that is triggered as part of a Buildkite CI step.

          See https://buildkite.com/docs/agent/v3/cli-meta-data
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :set,
            env_name: 'BUILDKITE_METADATA_SET',
            description: 'The hash of key/value pairs of the meta-data to set',
            type: Hash,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :get,
            env_name: 'BUILDKITE_METADATA_GET',
            description: 'The key of the metadata to get the value of',
            type: String,
            optional: true,
            default_value: nil
          ),
        ]
      end

      def self.return_value
        'The value of the Buildkite metadata corresponding to the provided `get` key. `nil` if no `get` parameter was provided.'
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
