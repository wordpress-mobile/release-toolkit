module Fastlane
  module Actions
    class AndroidLaunchEmulatorAction < Action
      def self.run(params)
        helper = Fastlane::Helper::Android::EmulatorHelper.new
        helper.launch_avd(
          name: params[:avd_name],
          cold_boot: params[:cold_boot],
          wipe_data: params[:wipe_data]
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Boots an Android emulator using the given AVD name'
      end

      def self.details
        description
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :avd_name,
                                       env_name: 'FL_ANDROID_LAUNCH_EMULATOR_AVD_NAME',
                                       description: 'The name of the AVD to boot',
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :cold_boot,
                                       env_name: 'FL_ANDROID_LAUNCH_EMULATOR_COLD_BOOT',
                                       description: 'Indicate if we want a cold boot (true) of if we prefer booting from a snapshot (false)',
                                       type: Fastlane::Boolean,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :wipe_data,
                                       env_name: 'FL_ANDROID_LAUNCH_EMULATOR_WIPE_DATA',
                                       description: 'Indicate if we want to wipe the device data before booting the AVD, so it is like it were a brand new device',
                                       type: Fastlane::Boolean,
                                       default_value: true),
        ]
      end

      def self.output
      end

      def self.return_value
        'The serial of the emulator that was created after booting the AVD (e.g. `emulator-5554`)'
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
