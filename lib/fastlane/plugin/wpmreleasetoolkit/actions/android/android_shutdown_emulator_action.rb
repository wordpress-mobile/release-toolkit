module Fastlane
  module Actions
    class AndroidShutdownEmulatorAction < Action
      def self.run(params)
        helper = Fastlane::Helper::Android::EmulatorHelper.new
        helper.shut_down_emulators!(serials: params[:serial])
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Shuts down Android emulators'
      end

      def self.details
        description
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :serial,
                                       env_name: 'FL_ANDROID_SHUTDOWN_EMULATOR_SERIAL',
                                       description: 'The serial(s) of the emulators to shut down. If not provided (nil), will shut them all down',
                                       type: Array,
                                       optional: true,
                                       default_value: nil),
        ]
      end

      def self.output
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
