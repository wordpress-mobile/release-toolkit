# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'uri'
require 'json'
require_relative '../../helper/apps_cdn_helper'

module Fastlane
  module Actions
    module SharedValues
      APPS_CDN_UPLOADED_FILE_URL = :APPS_CDN_UPLOADED_FILE_URL
      APPS_CDN_UPLOADED_FILE_ID = :APPS_CDN_UPLOADED_FILE_ID
      APPS_CDN_UPLOADED_POST_ID = :APPS_CDN_UPLOADED_POST_ID
      APPS_CDN_UPLOADED_POST_URL = :APPS_CDN_UPLOADED_POST_URL
    end

    class UploadBuildToAppsCdnAction < Action
      # See https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-resource-type.php
      RESOURCE_TYPE = 'Build'
      # See https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-build-type.php
      VALID_BUILD_TYPES = %w[
        Alpha
        Beta
        Nightly
        Production
        Prototype
      ].freeze
      # See https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-platform.php
      VALID_PLATFORMS = [
        'Android',
        'iOS',
        'Mac - Silicon',
        'Mac - Intel',
        'Mac - Any',
        'Windows - x86',
        'Windows - x64',
        'Windows - ARM64',
        'Microsoft Store - x86',
        'Microsoft Store - x64',
        'Microsoft Store - ARM64',
        'Linux - x64',
        'Linux - ARM64',
      ].freeze
      # See https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-install-type.php
      VALID_INSTALL_TYPES = [
        'Full Install',
        'Update',
      ].freeze
      def self.run(params)
        UI.message('Uploading build to Apps CDN...')

        file_path = params[:file_path]
        UI.user_error!("File not found at path '#{file_path}'") unless File.exist?(file_path)

        uri = Helper::AppsCdnHelper.rest_v1_1_url(site_id: params[:site_id], path: 'media/new')

        # Create the request body and headers
        parameters = {
          product: params[:product],
          build_type: params[:build_type],
          visibility: params[:visibility].to_s.capitalize,
          platform: params[:platform],
          resource_type: RESOURCE_TYPE,
          install_type: params[:install_type],
          version: params[:version],
          build_number: params[:build_number], # Optional: may be nil
          minimum_system_version: params[:minimum_system_version], # Optional: may be nil
          critical_update: params[:critical_update], # Optional: may be nil
          phased_rollout_interval: params[:phased_rollout_interval], # Optional: may be nil
          post_status: params[:post_status], # Optional: may be nil
          release_notes: params[:release_notes], # Optional: may be nil
          sha: params[:sha], # Optional: may be nil
          error_on_duplicate: params[:error_on_duplicate] # defaults to false
        }.compact
        request_body, content_type = build_multipart_request(parameters: parameters, file_path: file_path)

        # Create and send the HTTP request
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = request_body
        request['Content-Type'] = content_type
        request['Accept'] = 'application/json'
        request['Authorization'] = "Bearer #{params[:api_token]}"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        # Handle the response
        case response
        when Net::HTTPSuccess
          result = parse_successful_response(response.body)

          Actions.lane_context[SharedValues::APPS_CDN_UPLOADED_POST_ID] = result[:post_id]
          Actions.lane_context[SharedValues::APPS_CDN_UPLOADED_POST_URL] = result[:post_url]
          Actions.lane_context[SharedValues::APPS_CDN_UPLOADED_FILE_ID] = result[:media_id]
          Actions.lane_context[SharedValues::APPS_CDN_UPLOADED_FILE_URL] = result[:media_url]

          UI.success('Build successfully uploaded to Apps CDN')
          UI.message("Post ID: #{result[:post_id]}")
          UI.message("Post URL: #{result[:post_url]}")

          result
        else
          UI.error("Failed to upload build to Apps CDN: #{response.code} #{response.message}")
          UI.error(response.body)
          UI.user_error!('Upload to Apps CDN failed')
        end
      end

      # Builds a multipart request body for the WordPress.com Media API
      #
      # @param parameters [Hash] The parameters to include in the request as top-level form fields
      # @param file_path [String] The path to the file to upload
      # @return [Array] An array containing the request body and the content-type header
      #
      def self.build_multipart_request(parameters:, file_path:)
        boundary = "----WebKitFormBoundary#{SecureRandom.hex(10)}"
        content_type = "multipart/form-data; boundary=#{boundary}"
        post_body = []

        # Add the file first
        post_body << "--#{boundary}"
        post_body << "Content-Disposition: form-data; name=\"media[]\"; filename=\"#{File.basename(file_path)}\""
        post_body << 'Content-Type: application/octet-stream'
        post_body << ''
        post_body << File.binread(file_path)

        # Add each parameter as a separate form field
        parameters.each do |key, value|
          post_body << "--#{boundary}"
          post_body << "Content-Disposition: form-data; name=\"#{key}\""
          post_body << ''
          post_body << value.to_s
        end

        # Add the closing boundary
        post_body << "--#{boundary}--"

        [post_body.join("\r\n"), content_type]
      end

      # Parse the successful response and return a hash with the upload details
      #
      # @param response_body [String] The raw response body from the API
      # @return [Hash] A hash containing the upload details
      def self.parse_successful_response(response_body)
        json_response = JSON.parse(response_body)
        media = json_response['media'].first
        media_id = media['ID']
        media_url = media['URL']
        post_id = media['post_ID']

        # Compute the post URL using the same base URL as media_url
        post_url = URI.parse(media_url)
        post_url.path = '/'
        post_url.query = "p=#{post_id}"
        post_url = post_url.to_s

        {
          post_id: post_id,
          post_url: post_url,
          media_id: media_id,
          media_url: media_url,
          mime_type: media['mime_type']
        }
      end

      def self.description
        'Uploads a build binary to the Apps CDN'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns a Hash containing the upload result: { post_id:, post_url:, media_id:, media_url:, mime_type: }. On error, raises a FastlaneError.'
      end

      def self.details
        <<~DETAILS
          Uploads a build binary file to a WordPress blog that has the Apps CDN plugin enabled.
          See PCYsg-15tP-p2 internal a8c documentation for details about the Apps CDN plugin.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :site_id,
            env_name: 'APPS_CDN_SITE_ID',
            description: 'The WordPress.com CDN site ID to upload the media to',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Site ID cannot be empty') if value.to_s.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :product,
            env_name: 'APPS_CDN_PRODUCT',
            # Valid values can be found at https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-product.php
            description: 'The product the build belongs to (e.g. \'WordPress.com Studio\')',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Product cannot be empty') if value.to_s.empty?
              # Unlike for other parameters, we don't validate the product value against a list of valid values because we expect this list of
              # supported products to be updated on the backend from time to time and we don't want to have to update the toolkit every time for it.
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :platform,
            env_name: 'APPS_CDN_PLATFORM',
            # Valid values can be found at https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-platform.php
            description: "The platform the build runs on. One of: #{VALID_PLATFORMS.join(', ')}",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Platform cannot be empty') if value.to_s.empty?
              UI.user_error!("Platform must be one of: #{VALID_PLATFORMS.join(', ')}") unless VALID_PLATFORMS.include?(value)
            end
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
          FastlaneCore::ConfigItem.new(
            key: :build_type,
            # Valid values can be found at https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-build-type.php
            description: "The type of the build. One of: #{VALID_BUILD_TYPES.join(', ')}",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Build type cannot be empty') if value.to_s.empty?
              UI.user_error!("Build type must be one of: #{VALID_BUILD_TYPES.join(', ')}") unless VALID_BUILD_TYPES.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :install_type,
            description: "The install type for the build. One of: #{VALID_INSTALL_TYPES.join(', ')}",
            default_value: 'Full Install',
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Install type must be one of: #{VALID_INSTALL_TYPES.join(', ')}") unless VALID_INSTALL_TYPES.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :visibility,
            description: 'The visibility of the build (:internal or :external)',
            optional: false,
            type: Symbol,
            verify_block: Helper::AppsCdnHelper.verify_visibility
          ),
          FastlaneCore::ConfigItem.new(
            key: :post_status,
            description: 'The post status (defaults to \'publish\')',
            optional: true,
            default_value: 'publish',
            type: String,
            verify_block: Helper::AppsCdnHelper.verify_post_status
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
            key: :critical_update,
            description: 'Whether the build is a critical update',
            optional: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :phased_rollout_interval,
            description: 'The interval for the phased rollout (in seconds)',
            optional: true,
            type: Integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :release_notes,
            description: 'The release notes to show with the build on the blog frontend',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :sha,
            description: 'A string representing the release, e.g. the most recent commit hash, cryptographic token, etc',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :error_on_duplicate,
            description: 'If true, the action will error if a build matching the same metadata already exists. If false, any potential existing build matching the same metadata will be updated to replace the build with the new file',
            default_value: false,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_token,
            env_name: 'WPCOM_API_TOKEN',
            description: 'The WordPress.com API token for authentication',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('API token cannot be empty') if value.to_s.empty?
            end
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.output
        [
          ['APPS_CDN_UPLOADED_FILE_URL', 'The URL of the uploaded file'],
          ['APPS_CDN_UPLOADED_FILE_ID', 'The ID of the uploaded file'],
          ['APPS_CDN_UPLOADED_POST_ID', 'The ID of the post / page created for the uploaded build'],
          ['APPS_CDN_UPLOADED_POST_URL', 'The URL of the post / page created for the uploaded build'],
        ]
      end

      def self.example_code
        [
          'upload_build_to_apps_cdn(
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
          'upload_build_to_apps_cdn(
            site_id: "12345678",
            api_token: ENV["WPCOM_API_TOKEN"],
            product: "WordPress.com Studio",
            build_type: "Beta",
            visibility: :external,
            platform: "Android",
            version: "20.0",
            build_number: "42",
            file_path: "path/to/app.apk",
            error_on_duplicate: true
          )',
        ]
      end
    end
  end
end
