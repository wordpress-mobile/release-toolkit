module Fastlane
  module Actions
    class AndroidCreateAvdAction < Action
      def self.run(params)
        device_model = params[:device_model]
        api_level = params[:api_level]
        avd_name = params[:avd_name]
        sdcard = params[:sdcard]

        helper = Fastlane::Helper::Android::EmulatorHelper.new

        # Ensure we have the system image needed for creating the AVD with this API level
        system_image = params[:system_image] || helper.install_system_image(api: api_level)

        # Create the AVD for device, API and system image we need
        helper.create_avd(
          api: api_level,
          device: device_model,
          system_image:,
          name: avd_name,
          sdcard:
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Creates a new Android Virtual Device (AVD) for a specific device model and API level'
      end

      def self.details
        <<~DESC
          Creates a new Android Virtual Device (AVD) for a specific device model and API level.
          By default, it also installs the necessary system image (using `sdkmanager`) if needed before creating the AVD
        DESC
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :device_model,
                                       env_name: 'FL_ANDROID_CREATE_AVD_DEVICE_MODEL',
                                       description: 'The device model code to use to create the AVD. Valid values can be found using `avdmanager list devices`',
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :api_level,
                                       env_name: 'FL_ANDROID_CREATE_AVD_API_LEVEL',
                                       description: 'The API level to use to install the necessary system-image and create the AVD',
                                       type: Integer,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :avd_name,
                                       env_name: 'FL_ANDROID_CREATE_AVD_AVD_NAME',
                                       description: 'The name to give to the created AVD. If not provided, will be derived from device model and API level',
                                       type: String,
                                       optional: true,
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :sdcard,
                                       env_name: 'FL_ANDROID_CREATE_AVD_SDCARD',
                                       description: 'The size of the SD card to use for the AVD',
                                       type: String,
                                       optional: true,
                                       default_value: '512M'),
          FastlaneCore::ConfigItem.new(key: :system_image,
                                       env_name: 'FL_ANDROID_CREATE_AVD_SYSTEM_IMAGE',
                                       description: 'The system image to use (as used/listed by `sdkmanager`). Defaults to the appropriate system image given the API level requested and the current machine\'s architecture',
                                       type: String,
                                       optional: true,
                                       default_value_dynamic: true,
                                       default_value: nil),
        ]
      end

      def self.output
      end

      def self.return_value
        'Returns the name of the created AVD'
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
