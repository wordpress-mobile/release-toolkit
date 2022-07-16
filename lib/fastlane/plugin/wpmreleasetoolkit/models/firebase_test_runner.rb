require 'json'
require 'uri'
require 'fileutils'
require 'google/cloud/storage'

module Fastlane
  class FirebaseTestRunner
    VALID_TEST_TYPES = %w[instrumentation robo].freeze

    def self.preflight(verify_gcloud_binary: true, verify_logged_in: true)
      verify_has_gcloud_binary! if verify_gcloud_binary
      verify_logged_in! if verify_logged_in
    end

    # Run a given APK and Test Bundle on the given device type.
    #
    # @param [String] apk_path Path to the application APK on disk.
    # @param [String] test_apk_path Path to the test runner APK on disk.
    # @param [FirebaseDevice] device The virtual device to run tests on.
    # @param [String] type The type of test to run.
    #
    def self.run_tests(apk_path:, test_apk_path:, device:, type: 'instrumentation')
      raise "Unable to find apk: #{apk_path}" unless File.file?(apk_path)
      raise "Unable to find apk: #{test_apk_path}" unless File.file?(test_apk_path)
      raise "Invalid Type: #{type}" unless VALID_TEST_TYPES.include?(type)

      command = Shellwords.join [
        'gcloud', 'firebase', 'test', 'android', 'run',
        '--type', type,
        '--app', apk_path,
        '--test', test_apk_path,
        '--device', device.to_s,
        '--verbosity', 'info',
      ]

      log_file_path = Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH]

      UI.message "Streaming log output to #{log_file_path}"
      Action.sh("#{command} 2>&1 | tee #{log_file_path}")

      # Make the file object available to other tasks
      result = FirebaseTestLabResult.new(log_file_path: log_file_path)
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE] = result

      result
    end

    # Downloads all files associated with a Firebase Test Run to the local machine.
    #
    # @param [FirebaseTestLabResult] result The result bundle for a given test run.
    # @param [String] destination The local directory to store all downloaded files.
    # @param [String] project_id The Google Cloud Project ID – required for Google Cloud Storage access.
    # @param [String] key_file_path The path to the key file – required for Google Cloud Storage access.
    #
    def self.download_result_files(result:, destination:, project_id:, key_file_path:)
      UI.user_error! 'You must pass a `FirebaseTestLabResult` to this method' unless result.is_a? Fastlane::FirebaseTestLabResult

      paths = result.raw_results_paths
      UI.user_error! "Log File doesn't contain a raw results URL" if paths.nil?

      FileUtils.mkdir_p(destination) unless File.directory?(destination)

      storage = Google::Cloud::Storage.new(
        project_id: project_id,
        credentials: key_file_path
      )

      # Set up the download
      bucket = storage.bucket(paths[:bucket])
      files_to_download = bucket.files(prefix: paths[:prefix])

      # Download the files
      UI.header "Downloading Results Files to #{destination}"
      files_to_download.each { |file| download_file(file: file, destination: destination) }
    end

    # Download a Google Cloud Storage file to the local machine, creating intermediate directories as needed.
    #
    # @param [Google::Cloud::Storage::File] file Usually provided via `bucket.files`.
    # @param [String] destination The local directory to store the file. It will retain its original name.
    #
    def self.download_file(file:, destination:)
      destination = File.join(destination, file.name)
      FileUtils.mkdir_p(File.dirname(destination))

      # Print our progress
      UI.message(file.name)

      file.download(destination)
    end

    def self.verify_has_gcloud_binary!
      Action.sh('command', '-v', 'gcloud', print_command: false, print_command_output: false)
    rescue StandardError
      UI.user_error!("The `gcloud` binary isn't available on this machine. Unable to continue.")
    end

    def self.verify_logged_in!
      UI.user_error!('You are not logged into Firebase on this machine. Unable to continue.') unless FirebaseAccount.authenticated?
    end
  end
end
