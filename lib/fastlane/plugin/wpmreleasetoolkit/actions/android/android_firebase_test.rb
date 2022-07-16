require 'securerandom'

module Fastlane
  module Actions
    module SharedValues
      FIREBASE_TEST_RESULT = :FIREBASE_TEST_LOG_FILE
      FIREBASE_TEST_LOG_FILE_PATH = :FIREBASE_TEST_LOG_FILE_PATH
    end

    class AndroidFirebaseTestAction < Action
      def self.run(params)
        validate_options(params)

        UI.user_error!('You must be logged in to Firebase prior to calling this action. Use the `FirebaseLogin` Action to log in if needed') unless Fastlane::FirebaseAccount.authenticated?

        # Log in to Firebase (and validate credentials)
        run_uuid = params[:test_run_id] || SecureRandom.uuid
        test_dir = params[:results_output_dir] || File.join(Dir.tmpdir(), run_uuid)

        # Set up the log file and output directory
        FileUtils.mkdir_p(test_dir)
        Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = File.join(test_dir, 'output.log')

        device = Fastlane::FirebaseDevice.new(
          model: params[:model],
          version: params[:version],
          locale: params[:locale],
          orientation: params[:orientation]
        )

        result = FirebaseTestRunner.run_tests(
          apk_path: params[:apk_path],
          test_apk_path: params[:test_apk_path],
          device: device,
          type: params[:type]
        )

        # Download all of the outputs from the job to the local machine
        FirebaseTestRunner.download_result_files(
          result: result,
          destination: test_dir,
          project_id: params[:project_id],
          key_file_path: params[:key_file]
        )

        FastlaneCore::UI.test_failure! "Firebase Tests failed – more information can be found at #{result.more_details_url}" unless result.success?

        UI.success 'Firebase Tests Complete'
      end

      # Fastlane doesn't eagerly validate options for us, so we'll do it first to have control over
      # when they're evalutated.
      def self.validate_options(params)
        available_options
          .reject { |opt| opt.optional || !opt.default_value.nil? }
          .map(&:key)
          .each { |k| params[k] }
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
            # `env_name` comes from the Google Cloud default: https://cloud.google.com/functions/docs/configuring/env-var
            env_name: 'GCP_PROJECT',
            description: 'The Project ID to test in',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :key_file,
            description: 'The key file used to authorize with Google Cloud',
            type: String,
            verify_block: proc do |value|
              UI.user_error!('The `:key_file` parameter is required') if value.empty?
              UI.user_error!("No Google Cloud Key file found at: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :apk_path,
            description: 'Path to the application APK on the local machine',
            type: String,
            verify_block: proc do |value|
              UI.user_error!('The `:apk_path` parameter is required') if value.empty?
              UI.user_error!("Invalid application APK: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :test_apk_path,
            description: 'Path to the test bundle APK on the local machine',
            type: String,
            verify_block: proc do |value|
              UI.user_error!('The `:test_apk_path` parameter is required') if value.empty?
              UI.user_error!("Invalid test APK: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :model,
            description: 'The device model to use to run the test',
            type: String,
            verify_block: proc do |value|
              UI.user_error!('The `:model` parameter is required') if value.empty?
              FirebaseTestRunner.verify_has_gcloud_binary!
              model_names = Fastlane::FirebaseDevice.valid_model_names
              UI.user_error!("Invalid Model Name: #{value}. Valid Model Names: #{model_names}") unless model_names.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: 'The Android version (API Level) to use to run the test',
            type: Integer,
            verify_block: proc do |value|
              FirebaseTestRunner.verify_has_gcloud_binary!
              version_numbers = Fastlane::FirebaseDevice.valid_version_numbers
              UI.user_error!("Invalid Version Number: #{value}. Valid Version Numbers: #{version_numbers}") unless version_numbers.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :locale,
            description: 'The locale code to use when running the test',
            type: String,
            default_value: 'en',
            verify_block: proc do |value|
              FirebaseTestRunner.verify_has_gcloud_binary!
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
            description: 'The type of test to run (e.g. `instrumentation` or `robo`)',
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
            default_value_dynamic: true,
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :results_output_dir,
            description: 'The path to the folder where we will store the results of this test run',
            default_value_dynamic: true,
            optional: true,
            type: String
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
