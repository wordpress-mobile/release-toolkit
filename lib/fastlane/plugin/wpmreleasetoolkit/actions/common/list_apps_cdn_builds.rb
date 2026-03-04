# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  module Actions
    class ListAppsCdnBuildsAction < Action
      VALID_POST_STATUS = %w[publish draft].freeze

      def self.run(params)
        UI.message('Listing Apps CDN builds...')

        base_url = "https://public-api.wordpress.com/wp/v2/sites/#{params[:site_id]}"

        # Build query parameters
        query_params = { 'per_page' => '100' }
        query_params['status'] = params[:post_status] if params[:post_status]

        # Look up the version taxonomy term ID by slug if version is specified
        if params[:version]
          version_slug = params[:version].tr('.', '-')
          version_term_id = lookup_term_id(base_url: base_url, api_token: params[:api_token], taxonomy: 'version', slug: version_slug)
          query_params['version'] = version_term_id.to_s
        end

        api_endpoint = "#{base_url}/a8c_cdn_build"
        uri = URI.parse(api_endpoint)
        uri.query = URI.encode_www_form(query_params)

        # Create and send the HTTP request
        request = Net::HTTP::Get.new(uri.request_uri)
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
          posts = JSON.parse(response.body)

          builds = posts.map do |post|
            classes = post['class_list'] || []
            {
              post_id: post['id'],
              title: post.dig('title', 'rendered'),
              status: post['status'],
              version: extract_class_prefix(classes, 'version-'),
              visibility: extract_class_prefix(classes, 'visibility-'),
              platform: extract_class_prefix(classes, 'platform-'),
              build_type: extract_class_prefix(classes, 'build_type-')
            }
          end

          UI.success("Found #{builds.size} Apps CDN build(s)")

          builds
        else
          UI.error("Failed to list Apps CDN builds: #{response.code} #{response.message}")
          UI.error(response.body)
          UI.user_error!('Listing of Apps CDN builds failed')
        end
      end

      # Look up a taxonomy term ID by its slug.
      #
      # @param base_url [String] The WP REST API v2 base URL (e.g. https://public-api.wordpress.com/wp/v2/sites/123)
      # @param api_token [String] The WordPress.com API token
      # @param taxonomy [String] The taxonomy name (e.g. 'version', 'visibility')
      # @param slug [String] The term slug to look up
      # @return [Integer] The term ID
      #
      def self.lookup_term_id(base_url:, api_token:, taxonomy:, slug:)
        uri = URI.parse("#{base_url}/#{taxonomy}?slug=#{slug}")

        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = 'application/json'
        request['Authorization'] = "Bearer #{api_token}"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.open_timeout = 10
          http.read_timeout = 30
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          terms = JSON.parse(response.body)
          UI.user_error!("No #{taxonomy} term found for slug '#{slug}'") if terms.empty?
          terms.first['id']
        else
          UI.user_error!("Failed to look up #{taxonomy} term '#{slug}': #{response.code} #{response.message}")
        end
      end

      # Extract a value from the class_list array by prefix.
      # e.g. extract_class_prefix(['visibility-external', 'platform-mac-silicon'], 'visibility-') => 'external'
      def self.extract_class_prefix(classes, prefix)
        classes.find { |c| c.start_with?(prefix) }&.delete_prefix(prefix)
      end

      def self.description
        'Lists builds on the Apps CDN with optional filtering'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns an Array of Hashes, each containing { post_id:, title:, status:, version:, visibility:, platform:, build_type: }. On error, raises a FastlaneError.'
      end

      def self.details
        <<~DETAILS
          Lists build posts on a WordPress blog that has the Apps CDN plugin enabled,
          using the WordPress.com REST API (WP v2). Supports filtering by post status
          and version (via taxonomy term lookup).
          See PCYsg-15tP-p2 internal a8c documentation for details about the Apps CDN plugin.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :site_id,
            env_name: 'APPS_CDN_SITE_ID',
            description: 'The WordPress.com CDN site ID to list builds from',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!('Site ID cannot be empty') if value.to_s.empty?
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
            key: :post_status,
            description: "Filter builds by post status ('publish' or 'draft')",
            optional: true,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Post status must be one of: #{VALID_POST_STATUS.join(', ')}") unless VALID_POST_STATUS.include?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: 'Filter builds by version string (e.g., "v1.7.5") — looks up the version taxonomy term by slug',
            optional: true,
            type: String
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'list_apps_cdn_builds(
            site_id: "12345678",
            api_token: ENV["WPCOM_API_TOKEN"]
          )',
          'list_apps_cdn_builds(
            site_id: "12345678",
            api_token: ENV["WPCOM_API_TOKEN"],
            post_status: "draft",
            version: "v1.7.5"
          )',
        ]
      end
    end
  end
end
