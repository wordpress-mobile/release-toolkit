# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  module Actions
    module SharedValues
      A8C_CDN_UPLOADED_FILE_URL = :A8C_CDN_UPLOADED_FILE_URL
      A8C_CDN_UPLOADED_FILE_ID = :A8C_CDN_UPLOADED_FILE_ID
    end

    class UploadAppToA8cCdnAction < Action
      # The resource type is constant for this action
      RESOURCE_TYPE = 'Build'

      # Valid post status values for WordPress media API
      VALID_POST_STATUS = %w[publish draft pending future private].freeze

      # Valid build types
      VALID_BUILD_TYPES = %w[Alpha Beta Nightly Production Prototype].freeze

      # Valid platforms
      VALID_PLATFORMS = ['Android', 'iOS', 'Mac - Silicon', 'Mac - Intel', 'Mac - Any', 'Windows'].freeze

      def self.run(params)
        UI.message('Uploading app to A8C CDN...')

        file_path = params[:file_path]

        # Validate file exists
        UI.user_error!("File not found at path '#{file_path}'") unless File.exist?(file_path)

        # Prepare the API endpoint
        api_endpoint = "https://public-api.wordpress.com/rest/v1.1/sites/#{params[:site_id]}/media/new"
        uri = URI.parse(api_endpoint)

        # Create the request body and headers
        attrs = {
          product: params[:product],
          build_type: params[:build_type],
          visibility: params[:visibility].to_s.capitalize,
          platform: params[:platform],
          resource_type: RESOURCE_TYPE,
          version: params[:version],
          build_number: params[:build_number], # Optional: may be nil
          minimum_system_version: params[:minimum_system_version], # Optional: may be nil
          post_status: params[:post_status], # Optional: may be nil
          release_notes: params[:release_notes] # Optional: may be nil
        }.compact

        request_body, content_type = build_multipart_request(attrs: attrs, file_path: file_path)

        # Create the HTTP request
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = request_body
        request['Content-Type'] = content_type
        request['Accept'] = 'application/json'
        request['Authorization'] = "Bearer #{params[:api_token]}"

        # Send the request
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        # Handle the response
        case response
        when Net::HTTPSuccess
          json_response = JSON.parse(response.body)

          # Extract the media details
          media = json_response['media'].first
          media_id = media['ID']
          media_url = media['URL']

          # Store in lane context
          Actions.lane_context[SharedValues::A8C_CDN_UPLOADED_FILE_URL] = media_url
          Actions.lane_context[SharedValues::A8C_CDN_UPLOADED_FILE_ID] = media_id

          UI.success('App successfully uploaded to A8C CDN')
          UI.message("Media ID: #{media_id}")
          UI.message("Media URL: #{media_url}")

          {
            id: media_id,
            url: media_url,
            response: json_response
          }
        else
          UI.error("Failed to upload app to A8C CDN: #{response.code} #{response.message}")
          UI.error("Response body: #{response.body}")
          UI.user_error!('Upload to A8C CDN failed')
        end
      end

      # Builds a multipart request body for the WordPress.com Media API
      # @param attrs [Hash] The attributes to include in the request
      # @param file_path [String] The path to the file to upload
      # @return [Array] An array containing the request body and the content-type header
      def self.build_multipart_request(attrs:, file_path:)
        boundary = "----WebKitFormBoundary#{SecureRandom.hex(10)}"
        content_type = "multipart/form-data; boundary=#{boundary}"

        # Start building the multipart form data
        post_body = []

        # Add metadata fields
        post_body << "--#{boundary}\r\n"
        post_body << "Content-Disposition: form-data; name=\"attrs\"\r\n\r\n"
        post_body << attrs.to_json
        post_body << "\r\n"

        # Add the file
        post_body << "--#{boundary}\r\n"
        post_body << "Content-Disposition: form-data; name=\"media[]\"; filename=\"#{File.basename(file_path)}\"\r\n"
        post_body << "Content-Type: application/octet-stream\r\n\r\n"
        post_body << File.binread(file_path)
        post_body << "\r\n--#{boundary}--\r\n"

        [post_body.join, content_type]
      end

      def self.description
        'Uploads an app binary to the Automattic CDN'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns a hash containing the uploaded file ID, URL, and the full API response'
      end

      def self.details
        'Uploads an app binary file to the Automattic CDN using the WordPress.com Media Upload API'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :site_id,
            description: 'The WordPress.com site ID to upload the media to',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Site ID cannot be empty') if value.to_s.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_token,
            description: 'WordPress.com API token for authentication',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('API token cannot be empty') if value.to_s.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :product,
            # Valid values can be found at https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-product.php
            description: 'The product the build belongs to (e.g. \'WordPress.com Studio\')',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Product cannot be empty') if value.to_s.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_type,
            # Valid values can be found at https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-build-type.php
            description: 'The type of the build (e.g. \'Beta\')',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Build type cannot be empty') if value.to_s.empty?
              UI.user_error!("Build type must be one of: #{VALID_BUILD_TYPES.join(', ')}") unless VALID_BUILD_TYPES.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :visibility,
            description: 'The visibility of the build (:internal or :external)',
            optional: false,
            type: Symbol,
            verify_block: proc do |value|
              UI.user_error!('Visibility must be either :internal or :external') unless %i[internal external].include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :platform,
            # Valid values can be found at https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-platform.php
            description: 'The platform the build runs on (e.g. \'Android\', \'iOS\', \'Mac - Silicon\', \'Mac - Intel\', \'Mac - Any\', \'Windows\')',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Platform cannot be empty') if value.to_s.empty?
              UI.user_error!("Platform must be one of: #{VALID_PLATFORMS.join(', ')}") unless VALID_PLATFORMS.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: 'The version string for the build (e.g. \'20.0\', \'17.8.1\')',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Version cannot be empty') if value.to_s.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_number,
            description: 'The build number for the build (e.g. \'42\')',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :minimum_system_version,
            description: 'The minimum version for the provided platform (e.g. \'13.0\' for macOS Ventura)',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :post_status,
            description: 'The post status (defaults to \'publish\')',
            optional: true,
            default_value: 'publish',
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Post status must be one of: #{VALID_POST_STATUS.join(', ')}") unless VALID_POST_STATUS.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :release_notes,
            description: 'The release notes to show with the build on the blog frontend',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :file_path,
            description: 'The path to the build file to upload',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("File not found at path '#{value}'") unless File.exist?(value)
            end
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'upload_app_to_a8c_cdn(
            site_id: "12345678",
            api_token: ENV["WPCOM_API_TOKEN"],
            product: "WordPress.com Studio",
            build_type: "Beta",
            visibility: :internal,
            platform: "Mac - Any",
            version: "20.0",
            build_number: "42",
            file_path: "path/to/app.zip"
          )',
        ]
      end
    end
  end
end
