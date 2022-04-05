module Fastlane
  module Actions
    require_relative '../../helper/android/android_firebase_helper'

    class AndroidFirebaseTestAction < Action
      def self.run(params)
        Fastlane::Helper::Android::FirebaseHelper.setup(key_file: params[:key_file])

        device = Fastlane::Helper::Android::FirebaseHelper::FirebaseDevice.new(
          model: params[:model],
          version: params[:version],
          locale: params[:locale],
          orientation: params[:orientation]
        )

        Fastlane::Helper::Android::FirebaseHelper.run_tests(
          device: device
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs the specified tests in Firebase Test Lab'
      end

      def self.details
        description
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :project_id,
            env_name: 'GCP_PROJECT',
            description: 'The Project ID to test in',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :key_file,
            env_name: 'GOOGLE_APPLICATION_CREDENTIALS',
            description: 'The key file used to authorize with Google Cloud',
            type: String,
            verify_block: proc do |value|
              next if File.file? value

              UI.user_error!("Invalid key file path: #{value}")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :model,
            description: 'The device model to run',
            type: String,
            verify_block: proc do |value|
              model_names = Fastlane::Helper::Android::FirebaseHelper::FirebaseDevice.valid_model_names
              next if model_names.include? value

              UI.user_error!("Invalid Model Name: #{value}. Valid Model Names: #{model_names}")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: 'The device version to run',
            type: Integer,
            verify_block: proc do |value|
              version_numbers = Fastlane::Helper::Android::FirebaseHelper::FirebaseDevice.valid_version_numbers
              next if version_numbers.include? value

              UI.user_error!("Invalid Version Number: #{value}. Valid Verison Numbers: #{version_numbers}")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :locale,
            description: 'The locale code to run in',
            type: String,
            default_value: 'en',
            verify_block: proc do |value|
              locale_codes = Fastlane::Helper::Android::FirebaseHelper::FirebaseDevice.valid_locales
              next if locale_codes.include? value

              UI.user_error!("Invalid Locale: #{value}. Valid Locales: #{locale_codes}")
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :orientation,
            description: 'Which orientation to run the device in',
            type: String,
            default_value: 'portrait',
            verify_block: proc do |value|
              orientations = Fastlane::Helper::Android::FirebaseHelper::FirebaseDevice.valid_orientations
              next if orientations.include? value

              UI.user_error!("Invalid Orientation: #{value}. Valid Orientations: #{orientations}")
            end
          ),
        ]
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
