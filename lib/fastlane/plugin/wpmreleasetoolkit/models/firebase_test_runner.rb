require 'json'
require 'uri'

module Fastlane
  class FirebaseTestRunner
    VALID_TEST_TYPES = %w[instrumentation robo].freeze

    def initialize(key_file:, automatic_login: true)
      raise "Unable to find key file: #{key_file}" unless File.file? key_file

      @key_file = key_file
      authenticate if automatic_login
    end

    def authenticate
      Action.sh(
        'gcloud', 'auth', 'activate-service-account',
        '--key-file', @key_file
      )
    end

    def run_tests(apk_path:, test_apk_path:, device:, type: 'instrumentation')
      raise "Unable to find apk: #{apk_path}" unless File.file? apk_path
      raise "Unable to find apk: #{test_apk_path}" unless File.file? test_apk_path
      raise "Invalid Type: #{type}" unless VALID_TEST_TYPES.include? type

      command = [
        'gcloud', 'firebase', 'test', 'android', 'run',
        '--type', Shellwords.escape(type),
        '--app', Shellwords.escape(apk_path),
        '--test', Shellwords.escape(test_apk_path),
        '--device', Shellwords.escape(device.to_s),
        '--verbosity', 'info',
      ].join(' ')

      log_file_path = Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH]
      UI.message "Streaming log output to #{log_file_path}"
      Action.sh("#{command} 2>&1 | tee #{log_file_path}")

      # Make the file object available to other tasks
      file = FirebaseTestLabLogFile.new(path: log_file_path)
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE] = file

      # Return `true` if it looks like the test passed
      !file.indicates_failure
    end

    def download_raw_results(log_file:, destination:)
      raise unless log_file.is_a? Fastlane::FirebaseTestLabLogFile

      paths = log_file.raw_results_paths
      raise "Log File doesn't contain a raw results URL" if paths.nil?

      FileUtils.mkdir_p(destination) unless File.directory? destination

      require 'google/cloud/storage'
      storage = Google::Cloud::Storage.new(
        project_id: Fastlane::Actions.lane_context[:FIREBASE_PROJECT_ID],
        credentials: Fastlane::Actions.lane_context[:FIREBASE_CREDENTIALS]
      )

      # Set up the download
      bucket = storage.bucket(paths[:bucket])
      files_to_download = bucket.files(prefix: paths[:prefix])

      # Download the files
      UI.header "Downloading Results Files to #{destination}"
      files_to_download.each { |file| download_file(file: file, destination: destination) }
    end

    def download_file(file:, destination:)
      destination = File.join(destination, file.name)
      FileUtils.mkdir_p(File.dirname(destination))

      # Print our progress
      UI.message(file.name)

      file.download(destination)
    end

    def self.verify_has_gcloud_binary
      Action.sh('command -v gcloud > /dev/null')
    rescue StandardError
      UI.user_error!("The `gcloud` binary isn't available on this machine. Unable to continue.")
    end
  end
end
