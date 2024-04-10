require 'yaml'

module Fastlane
  module Actions
    class IosCheckBetaDepsAction < Action
      def self.run(params)
        require_relative '../../helper/ios/ios_version_helper'
        require_relative '../../helper/ios/ios_git_helper'

        yaml = YAML.load_file(params[:lockfile])
        non_stable_pods = {} # Key will be pod name, value will be reason for flagging

        # Find pods referenced by commit and branch to a repo
        yaml['EXTERNAL SOURCES'].each do |pod, options|
          non_stable_pods[pod] = 'commit' if params[:report_commits] && options.key?(:commit)
          non_stable_pods[pod] = 'branch' if params[:report_branches] && options.key?(:branch)
        end

        # Find pods whose resolved version matches the regex
        version_pattern = params[:report_version_pattern]
        unless version_pattern.nil? || version_pattern.empty?
          regex = begin
            Regexp.new(version_pattern)
          rescue RegexpError
            UI.user_error!("Invalid regex pattern: `#{version_pattern}`")
          end
          resolved_pods = yaml['PODS'].flat_map { |entry| entry.is_a?(Hash) ? entry.keys : entry }
          resolved_pods.each do |line|
            (pod, version) = /(.*) \((.*)\)/.match(line)&.captures
            non_stable_pods[pod] = regex.source if regex.match?(version)
          end
        end

        message = ''
        if non_stable_pods.empty?
          message << ALL_PODS_STABLE_MESSAGE
        else
          message << NON_STABLE_PODS_MESSAGE
          non_stable_pods.sort.each do |pod, reason|
            message << " - #{pod} (currently points to #{reason})\n"
          end
        end
        UI.important(message)
        { message: message, pods: non_stable_pods }
      end

      #####################################################
      # @!group Documentation
      #####################################################

      ALL_PODS_STABLE_MESSAGE = 'All pods are pointing to a stable version. You can continue with the code freeze.'.freeze
      NON_STABLE_PODS_MESSAGE = "Please create a new stable version of those pods and update the Podfile to the newly released version before continuing with the code freeze:\n".freeze

      def self.description
        'Runs some prechecks before finalizing a release'
      end

      def self.details
        'Runs some prechecks before finalizing a release'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :lockfile,
            description: 'Path to the Podfile.lock to analyse',
            default_value: 'Podfile.lock',
            type: String,
            verify_block: proc do |value|
              UI.user_error!("File `#{value}` does not exist") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :report_commits,
            description: 'Whether to report pods referenced by commit',
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :report_branches,
            description: 'Whether to report pods referenced by branch',
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :report_version_pattern,
            description: 'Report any pod whose tag name or version constraint matches this Regex pattern. Set to empty string to ignore',
            default_value: '-beta|-rc',
            type: String
          ),
        ]
      end

      def self.output
      end

      def self.return_value
        <<~RETURN_VALUE
          A Hash with keys `message` and `pods`.
          - The `message` can be used to e.g. post a Buildkite annotation.
          - The `pods` is itself a `Hash` whose keys are the pod names and values are the reason for the violation
        RETURN_VALUE
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end
    end
  end
end
