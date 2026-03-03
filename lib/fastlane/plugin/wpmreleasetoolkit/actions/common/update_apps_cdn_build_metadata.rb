# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  module Actions
    class UpdateAppsCdnBuildMetadataAction < Action
      VALID_VISIBILITIES = %i[internal external].freeze
      VALID_POST_STATUS = %w[publish draft].freeze

      def self.run(params)
        UI.message("Updating Apps CDN build metadata for post #{params[:post_id]}...")

        api_endpoint = "https://public-api.wordpress.com/rest/v1.1/sites/#{params[:site_id]}/posts/#{params[:post_id]}"
        uri = URI.parse(api_endpoint)

        # Build the update form data
        form_data = {}
        form_data['terms[visibility]'] = params[:visibility].to_s.capitalize if params[:visibility]
        form_data['status'] = params[:post_status] if params[:post_status]

        UI.user_error!('No metadata to update. Provide at least one of: visibility, post_status') if form_data.empty?

        # Create and send the HTTP request
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = URI.encode_www_form(form_data)
        request['Content-Type'] = 'application/x-www-form-urlencoded'
        request['Accept'] = 'application/json'
        request['Authorization'] = "Bearer #{params[:api_token]}"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.open_timeout = 10
          http.read_timeout = 30
          http.request(request)
        end

        # Handle the response
        case response
        when Net::HTTPSuccess
          result = JSON.parse(response.body)
          post_id = result['ID']

          UI.success("Successfully updated Apps CDN build metadata for post #{post_id}")

          { post_id: post_id }
        else
          UI.error("Failed to update Apps CDN build metadata: #{response.code} #{response.message}")
          UI.error(response.body)
          UI.user_error!('Update of Apps CDN build metadata failed')
        end
      end

      def self.description
        'Updates metadata of an existing build on the Apps CDN'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns a Hash containing { post_id: }. On error, raises a FastlaneError.'
      end

      def self.details
        <<~DETAILS
          Updates metadata (such as visibility) for an existing build post on a WordPress blog
          that has the Apps CDN plugin enabled, using the WordPress.com REST API.
          See PCYsg-15tP-p2 internal a8c documentation for details about the Apps CDN plugin.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :site_id,
            env_name: 'APPS_CDN_SITE_ID',
            description: 'The WordPress.com CDN site ID where the build was uploaded',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Site ID cannot be empty') if value.to_s.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :post_id,
            description: 'The ID of the build post to update',
            optional: false,
            type: Integer,
            verify_block: proc do |value|
              UI.user_error!('Post ID must be a positive integer') unless value.is_a?(Integer) && value.positive?
            end
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
          FastlaneCore::ConfigItem.new(
            key: :visibility,
            description: 'The new visibility for the build (:internal or :external)',
            optional: true,
            type: Symbol,
            verify_block: proc do |value|
              UI.user_error!("Visibility must be one of: #{VALID_VISIBILITIES.map { "`:#{_1}`" }.join(', ')}") unless VALID_VISIBILITIES.include?(value.to_s.downcase.to_sym)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :post_status,
            description: "The new post status ('publish' or 'draft')",
            optional: true,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Post status must be one of: #{VALID_POST_STATUS.join(', ')}") unless VALID_POST_STATUS.include?(value)
            end
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'update_apps_cdn_build_metadata(
            site_id: "12345678",
            api_token: ENV["WPCOM_API_TOKEN"],
            post_id: 98765,
            visibility: :external
          )',
          'update_apps_cdn_build_metadata(
            site_id: "12345678",
            api_token: ENV["WPCOM_API_TOKEN"],
            post_id: 98765,
            visibility: :internal,
            post_status: "draft"
          )',
        ]
      end
    end
  end
end
