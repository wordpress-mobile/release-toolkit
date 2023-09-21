module Fastlane
  module Actions
    class BuildkiteAnnotateAction < Action
      def self.run(params)
        message = params[:message]
        context = params[:context]
        style = params[:style]

        if message.nil?
          # Delete an annotation, but swallow the error if the annotation didn't exist — to avoid having
          # this action failing or printing a red log for no good reason — hence the `|| true`
          ctx_param = "--context #{context.shellescape}" unless context.nil?
          sh("buildkite-agent annotation remove #{ctx_param} || true")
        else
          # Add new annotation using `buildkite-agent`
          extra_params = {
            context:,
            style:
          }.compact.flat_map { |k, v| ["--#{k}", v] }
          sh('buildkite-agent', 'annotate', *extra_params, params[:message])
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Add or remove annotations to the current Buildkite build'
      end

      def self.details
        <<~DETAILS
          Add or remove annotations to the current Buildkite build.

          Has to be run on a CI job (where a `buildkite-agent` is running), e.g. typically by a lane
          that is triggered as part of a Buildkite CI step.

          See https://buildkite.com/docs/agent/v3/cli-annotate
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :context,
            env_name: 'BUILDKITE_ANNOTATION_CONTEXT',
            description: 'The context of the annotation used to differentiate this annotation from others',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :style,
            env_name: 'BUILDKITE_ANNOTATION_STYLE',
            description: 'The style of the annotation (`success`, `info`, `warning` or `error`)',
            type: String,
            optional: true,
            verify_block: proc do |value|
              valid_values = %w[success info warning error]
              next if value.nil? || valid_values.include?(value)

              UI.user_error!("Invalid value `#{value}` for parameter `style`. Valid values are: #{valid_values.join(', ')}")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :message,
            description: 'The message to use in the new annotation. Supports GFM-Flavored Markdown. ' \
            + 'If message is nil, any existing annotation with the provided context will be deleted',
            type: String,
            optional: true,
            default_value: nil # nil message = delete existing annotation if any
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
