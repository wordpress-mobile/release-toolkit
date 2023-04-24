module Fastlane
  module Actions
    class IosRegisterCiMachineAction < Action
      def self.run(params)
        return unless other_action.is_ci

        require 'socket'
        require 'open3'

        hostname = Socket.gethostname
                         .delete_suffix('.local')
                         .delete_suffix('.shared')

        device_uuid, = Open3.capture2("system_profiler SPHardwareDataType | awk '/Hardware UUID/ { print $NF }'")
        device_uuid.strip!
        raise 'Failed to get device UUID' if device_uuid.nil?

        UI.message "Registering device #{device_uuid} for CI image #{hostname}"

        other_action.register_device(
          name: "CI - #{hostname}",
          udid: device_uuid,
          platform: 'mac',
          api_key_path: params[:api_key_path],
          team_id: params[:team_id]
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Register the current CI machine as a new device in the Apple Developer Portal'
      end

      def self.details
        <<~DETAILS
          Register the current CI machine as a new device in the Apple Developer Portal.

          As the action name suggests, this action is only meant to be run on a CI machine and does nothing if CI environment is not detected (via the `is_ci` action).
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :api_key_path,
            description: 'The path of the App Store Connect API key file',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :team_id,
            description: 'The ID of the Developer Portal team',
            type: String,
            optional: false
          ),
        ]
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :mac
      end
    end
  end
end
