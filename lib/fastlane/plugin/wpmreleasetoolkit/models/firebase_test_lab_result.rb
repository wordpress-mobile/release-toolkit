module Fastlane
  class FirebaseTestLabResult
    def initialize(log_file_path:)
      raise "No log file found at path #{log_file_path}" unless File.file? log_file_path

      @path = log_file_path
    end

    # Scan the log file to for indications that the Test Run failed
    def success?
      File.readlines(@path).any? { |line| line.include?('Passed') && line.include?('test cases passed') }
    end

    # Parse the log for the "More details are available..." URL
    def more_details_url
      File.readlines(@path)
          .flat_map { |line| URI.extract(line) }
          .find { |url| URI(url).host == 'console.firebase.google.com' && url.include?('/matrices/') }
    end

    # Parse the log for the Google Cloud Storage Bucket URL
    def raw_results_paths
      uri = File.readlines(@path)
                .flat_map { |line| URI.extract(line) }
                .map { |string| URI(string) }
                .find { |u| u.scheme == 'gs' }

      return nil if uri.nil?

      return {
        bucket: uri.host,
        prefix: uri.path.delete_prefix('/').chomp('/')
      }
    end
  end
end
