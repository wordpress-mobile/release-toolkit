require 'securerandom'

module Fastlane
  module Actions
    module SharedValues
      FIREBASE_TEST_RESULT = :FIREBASE_TEST_LOG_FILE
      FIREBASE_TEST_LOG_FILE_PATH = :FIREBASE_TEST_LOG_FILE_PATH
    end

    class AndroidFirebaseTestAction < Action
      def self.run(params)
        # Log in to Firebase (and validate credentials)
        test_runner = Fastlane::FirebaseTestRunner.new(key_file: params[:key_file])

        # Set up the log file and output directory
        FileUtils.mkdir_p(params[:results_output_dir])
        Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = File.join(params[:results_output_dir], 'output.log')

        device = Fastlane::FirebaseDevice.new(
          model: params[:model],
          version: params[:version],
          locale: params[:locale],
          orientation: params[:orientation]
        )

        result = test_runner.run_tests(
          apk_path: params[:apk_path],
          test_apk_path: params[:test_apk_path],
          device: device,
          type: params[:type]
        )

        # Download all of the outputs from the job to the local machine
        test_runner.download_result_files(
          result: result,
          destination: params[:results_output_dir],
          project_id: params[:project_id],
          key_file_path: params[:key_file]
        )

        FastlaneCore::UI.test_failure! "Firebase Tests failed – more information can be found at #{result.more_details_url}" unless result.success?

        UI.success 'Firebase Tests Complete'
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
        run_uuid = SecureRandom.uuid

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
              UI.user_error!("Invalid key file path: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :apk_path,
            description: 'The application APK',
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Invalid application APK: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :test_apk_path,
            description: 'The test APK',
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Invalid test APK: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :model,
            description: 'The device model to run',
            type: String,
            verify_block: proc do |value|
              model_names = Fastlane::FirebaseDevice.valid_model_names
              UI.user_error!("Invalid Model Name: #{value}. Valid Model Names: #{model_names}") unless model_names.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: 'The device version to run',
            type: Integer,
            verify_block: proc do |value|
              version_numbers = Fastlane::FirebaseDevice.valid_version_numbers
              UI.user_error!("Invalid Version Number: #{value}. Valid Verison Numbers: #{version_numbers}") unless version_numbers.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :locale,
            description: 'The locale code to run in',
            type: String,
            default_value: 'en',
            verify_block: proc do |value|
              locale_codes = Fastlane::FirebaseDevice.valid_locales
              UI.user_error!("Invalid Locale: #{value}. Valid Locales: #{locale_codes}") unless locale_codes.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :orientation,
            description: 'Which orientation to run the device in',
            type: String,
            default_value: 'portrait',
            verify_block: proc do |value|
              orientations = Fastlane::FirebaseDevice.valid_orientations
              UI.user_error!("Invalid Orientation: #{value}. Valid Orientations: #{orientations}") unless orientations.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :type,
            description: 'Which type of test are we running?',
            type: String,
            default_value: 'instrumentation',
            verify_block: proc do |value|
              types = Fastlane::FirebaseTestRunner::VALID_TEST_TYPES
              UI.user_error!("Invalid Test Type: #{value}. Valid Types: #{types}") unless types.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :test_run_id,
            description: 'A unique ID used to identify this test run',
            type: String,
            default_value: run_uuid,
            default_value_dynamic: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :results_output_dir,
            description: 'Where should we store the results of this test run?',
            type: String,
            default_value: File.join(Dir.tmpdir(), run_uuid),
            default_value_dynamic: true
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
