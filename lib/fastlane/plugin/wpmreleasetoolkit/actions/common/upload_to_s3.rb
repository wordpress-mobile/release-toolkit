require 'fastlane/action'
require 'digest/sha1'

module Fastlane
  module Actions
    module SharedValues
      S3_UPLOADED_FILE_PATH = :S3_UPLOADED_FILE_PATH
    end

    class UploadToS3Action < Action
      def self.run(params)
        file_path = params[:file]
        file_name = File.basename(file_path)
        UI.user_error!("Unable to read file at #{file_path}") unless File.file?(file_path)

        bucket = params[:bucket]
        key = params[:key]

        UI.user_error!('You must provide a valid bucket name') if bucket.empty?
        UI.user_error!('You must provide a valid key') if key.is_a?(String) && key.empty?

        key = file_name if key.nil?

        if params[:auto_prefix] == true
          file_name_hash = Digest::SHA1.hexdigest(file_name)
          key = [file_name_hash, key].join('/')
        end

        UI.user_error!("File already exists at #{key}") if file_is_already_uploaded?(bucket, key)

        UI.message("Uploading #{file_path} to: #{key}")

        File.open(file_path, 'rb') do |file|
          Aws::S3::Client.new().put_object(
            body: file,
            bucket: bucket,
            key: key
          )
        rescue Aws::S3::Errors::ServiceError => e
          UI.crash!("Unable to upload file to S3: #{e.message}")
        end

        UI.success('Upload Complete')

        Actions.lane_context[SharedValues::S3_UPLOADED_FILE_PATH] = key

        return key
      end

      def self.file_is_already_uploaded?(bucket, key)
        response = Aws::S3::Client.new().head_object(
          bucket: bucket,
          key: key
        )
        return (response[:content_length]).positive?
      rescue Aws::S3::Errors::NotFound
        return false
      end

      def self.description
        'Uploads a given file to S3'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns the object\'s derived S3 key'
      end

      def self.details
        # Optional:
        'Uploads a file to S3, and makes a pre-signed URL available in the lane context'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :bucket,
            description: 'The bucket that will store the file',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :key,
            description: 'The path to the file within the bucket',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :file,
            description: 'The path to the local file on disk',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :auto_prefix,
            description: 'Generate a derived prefix based on the filename that makes it harder to guess the URL to the uploaded object',
            optional: true,
            default_value: true,
            type: Boolean
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
