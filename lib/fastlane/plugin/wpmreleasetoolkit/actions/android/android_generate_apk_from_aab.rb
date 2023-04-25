module Fastlane
  module Actions
    class AndroidGenerateApkFromAabAction < Action
      def self.generate_command(aab_file_path, apk_output_file_path, keystore_path, keystore_password, keystore_key_alias, signing_key_password)
        command = "bundletool build-apks --mode universal --bundle #{aab_file_path} --output-format DIRECTORY --output #{apk_output_file_path} "
        code_sign_arguments = "--ks #{keystore_path} --ks-pass #{keystore_password} --ks-key-alias #{keystore_key_alias} --key-pass #{signing_key_password} "
        move_and_cleanup_command = "&& mv #{apk_output_file_path}/universal.apk #{apk_output_file_path}_tmp && rm -rf #{apk_output_file_path} && mv #{apk_output_file_path}_tmp #{apk_output_file_path}"

        # Attempt to code sign the APK if a keystore_path parameter is specified
        command += code_sign_arguments unless keystore_path.nil?

        # Move and rename the universal.apk file to the specified output path and cleanup the directory created by bundletool
        command += move_and_cleanup_command

        return command
      end

      def self.run(params)
        begin
          sh('command -v bundletool > /dev/null')
        rescue StandardError
          UI.user_error!('bundletool is not installed. Please install it using the instructions at https://developer.android.com/studio/command-line/bundletool.')
          raise
        end

        # If no AAB param was provided, attempt to get it from the lane context
        # First GRADLE_ALL_AAB_OUTPUT_PATHS if only one
        # Second GRADLE_AAB_OUTPUT_PATH if it is set
        # Else use the specified parameter value
        if params[:aab_file_path].nil?
          all_aab_paths = Actions.lane_context[SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] || []
          aab_file_path = if all_aab_paths.count == 1
                            all_aab_paths.first
                          else
                            Actions.lane_context[SharedValues::GRADLE_AAB_OUTPUT_PATH]
                          end
        else
          aab_file_path = params[:aab_file_path]
        end

        # If no AAB file path was found, raise an error
        if aab_file_path.nil?
          UI.user_error!('No AAB file path was specified and none was found in the lane context. Please specify the `aab_file_path` parameter or ensure that the relevant build action has been run prior to this action.')
          raise
        end

        apk_output_file_path = params[:apk_output_file_path]
        keystore_path = params[:keystore_path]
        keystore_password = params[:keystore_password]
        keystore_key_alias = params[:keystore_key_alias]
        signing_key_password = params[:signing_key_password]

        sh(generate_command(aab_file_path, apk_output_file_path, keystore_path, keystore_password, keystore_key_alias, signing_key_password))
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates an APK from the specified AAB'
      end

      def self.details
        'Generates an APK from the specified AAB'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :aab_file_path,
            env_name: 'ANDROID_AAB_FILE_PATH',
            description: 'The path to the AAB file. If not speicified, the action will attempt to read from the lane context using the `SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS` and `SharedValues::GRADLE_AAB_OUTPUT_PATH` keys',
            type: String,
            optional: true,
            default_value: nil,
            verify_block: proc { |p| UI.user_error!("AAB path `#{p}` is not a valid file path.") unless File.file?(p) }
          ),
          FastlaneCore::ConfigItem.new(
            key: :apk_output_file_path,
            env_name: 'ANDROID_APK_OUTPUT_PATH',
            description: 'The output path where the APK file will be generated. The directory will be created if it does not yet exist',
            type: String,
            optional: false,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_path,
            env_name: 'ANDROID_KEYSTORE_PATH',
            description: 'The path to the keystore file',
            type: String,
            optional: true,
            default_value: nil,
            verify_block: proc { |p| UI.user_error!("Keystore file path `#{p}` is not a valid file path.") unless File.file?(p) || p.nil }
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_password,
            env_name: 'ANDROID_KEYSTORE_PASSWORD',
            description: 'The password for the keystore',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_key_alias,
            env_name: 'ANDROID_KEYSTORE_KEY_ALIAS',
            description: 'The alias of the key in the keystore',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :signing_key_password,
            env_name: 'ANDROID_SIGNING_KEY_PASSWORD',
            description: 'The password for the signing key',
            type: String,
            optional: true,
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
