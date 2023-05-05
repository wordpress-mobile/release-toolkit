module Fastlane
  module Actions
    class AndroidGenerateApkFromAabAction < Action
      def self.run(params)
        begin
          sh('command', '-v', 'bundletool', print_command: false, print_command_output: false)
        rescue StandardError
          UI.user_error!(MISSING_BUNDLETOOL_ERROR_MESSAGE)
        end

        # Parse input parameters
        aab_file_path = parse_aab_param(params)
        apk_output_file_path = params[:apk_output_file_path] || Pathname(aab_file_path).sub_ext('.apk').to_s
        code_sign_arguments = {
          '--ks': params[:keystore_path],
          '--ks-pass': params[:keystore_password],
          '--ks-key-alias': params[:keystore_key_alias],
          '--key-pass': params[:signing_key_password]
        }.compact.flatten.map(&:to_s)

        if File.directory?(apk_output_file_path)
          apk_output_file_path = File.join(apk_output_file_path, "#{File.basename(aab_file_path, '.aab')}.apk")
        end

        Dir.mktmpdir('a8c-release-toolkit-bundletool-') do |tmpdir|
          sh(
            'bundletool', 'build-apks',
            '--mode', 'universal',
            '--bundle', aab_file_path,
            '--output-format', 'DIRECTORY',
            '--output', tmpdir,
            *code_sign_arguments
          )
          FileUtils.mkdir_p(File.dirname(apk_output_file_path)) # Create destination directory if it doesn't exist yet
          FileUtils.mv(File.join(tmpdir, 'universal.apk'), apk_output_file_path)
        end

        apk_output_file_path
      end

      #####################################################

      def self.parse_aab_param(params)
        # If no AAB param was provided, attempt to get it from the lane context
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
          UI.user_error!(NO_AAB_ERROR_MESSAGE)
        elsif !File.file?(aab_file_path)
          UI.user_error!("The file `#{aab_file_path}` was not found. Please provide a path to an existing file.")
        end

        aab_file_path
      end

      MISSING_BUNDLETOOL_ERROR_MESSAGE = 'bundletool is not installed. Please install it using the instructions at https://developer.android.com/studio/command-line/bundletool.'.freeze
      NO_AAB_ERROR_MESSAGE = 'No AAB file path was specified and none was found in the lane context. Please specify the `aab_file_path` parameter or ensure that the `gradle` action has been run prior to this action.'.freeze

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generates an APK from the specified AAB'
      end

      def self.details
        'Generates an APK file from the specified AAB file using `bundletool`'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :aab_file_path,
            env_name: 'ANDROID_AAB_FILE_PATH',
            description: 'The path to the AAB file. If not specified, the action will attempt to read from the lane context using the `SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS` and `SharedValues::GRADLE_AAB_OUTPUT_PATH` keys',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :apk_output_file_path,
            env_name: 'ANDROID_APK_OUTPUT_PATH',
            description: 'The path of the output APK file to generate. If not specified, will use the same path and basename as the `aab_file_path` but with an `.apk` file extension',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_path,
            env_name: 'ANDROID_KEYSTORE_PATH',
            description: 'The path to the keystore file (if you want to codesign the APK)',
            type: String,
            optional: true,
            default_value: nil,
            verify_block: proc { |p| UI.user_error!("Keystore file path `#{p}` is not a valid file path.") unless p.nil? || File.file?(p) }
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_password,
            env_name: 'ANDROID_KEYSTORE_PASSWORD',
            description: 'The password for the keystore (if you want to codesign the APK)',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_key_alias,
            env_name: 'ANDROID_KEYSTORE_KEY_ALIAS',
            description: 'The alias of the key in the keystore (if you want to codesign the APK)',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :signing_key_password,
            env_name: 'ANDROID_SIGNING_KEY_PASSWORD',
            description: 'The password for the signing key (if you want to codesign the APK)',
            type: String,
            optional: true,
            default_value: nil
          ),
        ]
      end

      def self.return_type
        :string
      end

      def self.return_value
        'The path to the APK that has been generated'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == 'android'
      end
    end
  end
end
