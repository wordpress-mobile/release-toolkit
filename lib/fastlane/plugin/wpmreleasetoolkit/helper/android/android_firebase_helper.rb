require 'json'
require 'uri'

module Fastlane
  module Helper
    module Android
      module FirebaseHelper
        def self.run_tests(apk_path:, test_apk_path:, device:, type: 'instrumentation')
          raise "Unable to find apk: #{apk_path}" unless File.file? apk_path
          raise "Unable to find apk: #{test_apk_path}" unless File.file? test_apk_path
          raise "Invalid Type: #{type}" unless valid_test_types.include? type

          command = [
            'gcloud', 'firebase', 'test', 'android', 'run',
            '--type', Shellwords.escape(type),
            '--app', Shellwords.escape(apk_path),
            '--test', Shellwords.escape(test_apk_path),
            '--device', Shellwords.escape(device.to_s),
            '--verbosity', 'info',
          ].join(' ')

          log_file = Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH]
          UI.message "Streaming log output to #{log_file}"
          Action.sh("#{command} 2>&1 | tee #{log_file}")

          # Exit `true` if we can't find `Failed` in the log output
          File.readlines(log_file).all? { |line| !line.include? 'Failed' }
        end

        def self.download_raw_results
          paths = raw_results_paths
          return if paths.nil?

          destination = Fastlane::Actions.lane_context[:FIREBASE_TEST_RESULTS_FILE_PATH]

          FileUtils.mkdir_p(destination)

          require 'google/cloud/storage'
          storage = Google::Cloud::Storage.new(
            project_id: Fastlane::Actions.lane_context[:FIREBASE_PROJECT_ID],
            credentials: Fastlane::Actions.lane_context[:FIREBASE_CREDENTIALS]
          )

          # Set up the download
          bucket = storage.bucket(paths[:bucket])
          files_to_download = bucket.files(prefix: paths[:prefix])

          UI.header "Downloading Results Files to #{destination}" # a big box

          # Download the files
          files_to_download.each { |file| download_file(file: file, destination: destination) }
        end

        def self.download_file(file:, destination:)
          destination = File.join(destination, file.name)
          FileUtils.mkdir_p(File.dirname(destination))

          # Print our progress
          UI.message(file.name)

          file.download(destination)
        end

        def self.project=(project_id)
          Fastlane::Actions.lane_context[:FIREBASE_PROJECT_ID] = project_id
          Action.sh('gcloud', 'config', 'set', 'project', project_id)
        end

        def self.setup(key_file:)
          raise "Unable to find key file: #{key_file}" unless File.file? key_file

          Action.sh(
            'gcloud', 'auth', 'activate-service-account',
            '--key-file', key_file
          )

          # Assuming the action above was successful, we can store this for future use
          Fastlane::Actions.lane_context[:FIREBASE_CREDENTIALS] = key_file
        end

        # Get the "More details are available..." URL from the log
        def self.more_details_url
          log_file = Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH]
          return nil unless File.file? log_file

          File.readlines(log_file)
              .map { |line| URI.extract(line) }
              .flatten
              .compact
              .filter { |string| string.include? 'matrices' }
              .first
        end

        # Get the Google Cloud Storage Bucket URL to the raw results from the log
        def self.raw_results_paths
          log_file = Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH]
          return nil unless File.file? log_file

          uri = File.readlines(log_file)
                    .map { |line| URI.extract(line) }
                    .flatten
                    .compact
                    .map { |string| URI(string) }
                    .filter { |u| u.scheme == 'gs' }
                    .first

          return nil if uri.nil?

          return {
            bucket: uri.host,
            prefix: uri.path.delete_prefix('/').chomp('/')
          }
        end

        def self.verify_has_gcloud_binary
          Action.sh('command -v gcloud > /dev/null')
        rescue StandardError
          UI.user_error!("The `gcloud` binary isn't available on this machine. Unable to continue.")
        end

        def self.valid_test_types
          %w[instrumentation robo]
        end
      end
    end
  end
end
