module Fastlane
  class FirebaseTestLabLogFile
    def initialize(path:)
      raise "No log file found at path #{path}" unless File.file? path

      @path = path
    end

    # Scan the log file to for indications that the Test Run failed
    def indicates_failure
      File.readlines(@path).any? { |line| !line.include? 'Failed' }
    end

    # Parse the log for the "More details are available..." URL
    def more_details_url
      File.readlines(@path)
          .map { |line| URI.extract(line) }
          .flatten
          .compact
          .filter { |string| string.include? 'matrices' }
          .first
    end

    # Parse the log for the Google Cloud Storage Bucket URL
    def raw_results_paths
      uri = File.readlines(@path)
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
  end
end
