module Fastlane
  module Actions
    class BundletoolGenerateUniversalSignedApkAction < Action
      def self.run(params)
        aab_path = params[:aab_path]
        apk_output_path = params[:apk_output_path]
        keystore_path = params[:keystore_path]
        keystore_password = params[:keystore_password]
        keystore_key_alias = params[:keystore_key_alias]
        signing_key_password = params[:signing_key_password]

        begin
          sh('command -v bundletool > /dev/null')
        rescue StandardError
          UI.user_error!('bundletool is not installed. Please install it using the instructions at https://developer.android.com/studio/command-line/bundletool')
          raise
        end

        sh('bundletool', 'build-apks',
           '--mode', 'universal',
           '--bundle', aab_path,
           '--output-format', 'DIRECTORY',
           '--output', apk_output_path,
           '--ks', keystore_path,
           '--ks-pass', keystore_password,
           '--ks-key-alias', keystore_key_alias,
           '--key-pass', signing_key_password)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates a signed universal APK from the specified AAB'
      end

      def self.details
        'Generates a signed universal APK from the specified AAB'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :aab_path,
            env_name: 'BUNDLETOOL_AAB_PATH',
            description: 'The path to the AAB file',
            type: String,
            optional: false,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :apk_output_path,
            env_name: 'BUNDLETOOL_APK_OUTPUT_PATH',
            description: 'The path to the output directory where the APK will be generated',
            type: String,
            optional: false,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_path,
            env_name: 'BUNDLETOOL_KEYSTORE_PATH',
            description: 'The path to the keystore file',
            type: String,
            optional: false,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_password,
            env_name: 'BUNDLETOOL_KEYSTORE_PASSWORD',
            description: 'The password for the keystore',
            type: String,
            optional: false,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_key_alias,
            env_name: 'BUNDLETOOL_KEYSTORE_KEY_ALIAS',
            description: 'The alias of the key in the keystore',
            type: String,
            optional: false,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :signing_key_password,
            env_name: 'BUNDLETOOL_SIGNING_KEY_PASSWORD',
            description: 'The password for the signing key',
            type: String,
            optional: false,
            default_value: nil
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
