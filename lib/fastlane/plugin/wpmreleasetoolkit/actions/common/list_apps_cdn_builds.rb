# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'uri'
require 'json'

module Fastlane
  module Actions
    class ListAppsCdnBuildsAction < Action
      VALID_VISIBILITIES = %i[internal external].freeze

      # Extract the name of the first term in a taxonomy from an API post response.
      # Terms are keyed by display name, e.g. { 'Internal' => { 'name' => 'Internal', 'slug' => 'internal' } }
      def self.term_name(post, taxonomy)
        term = post.dig('terms', taxonomy)&.values&.first
        term&.[]('name')
      end

      def self.run(params)
        UI.message('Listing Apps CDN builds...')

        api_endpoint = "https://public-api.wordpress.com/rest/v1.1/sites/#{params[:site_id]}/posts"
        uri = URI.parse(api_endpoint)

        # Build query parameters
        query_params = {
          'type' => 'a8c_cdn_build',
          'number' => '100'
        }
        query_params['term[visibility]'] = params[:visibility].to_s.capitalize if params[:visibility]

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
          result = JSON.parse(response.body)
          posts = result['posts'] || []

          # Client-side filter by version if requested
          if params[:version]
            posts = posts.select { |post| post.dig('terms', 'version')&.key?(params[:version]) }
          end

          builds = posts.map do |post|
            {
              post_id: post['ID'],
              title: post['title'],
              version: term_name(post, 'version'),
              visibility: term_name(post, 'visibility')&.downcase,
              platform: term_name(post, 'platform'),
              build_type: term_name(post, 'build_type')
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

      def self.description
        'Lists builds on the Apps CDN with optional filtering'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns an Array of Hashes, each containing { post_id:, title:, version:, visibility:, platform:, build_type: }. On error, raises a FastlaneError.'
      end

      def self.details
        <<~DETAILS
          Lists build posts on a WordPress blog that has the Apps CDN plugin enabled,
          using the WordPress.com REST API. Supports filtering by visibility (server-side)
          and version (client-side).
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
            key: :visibility,
            description: 'Filter builds by visibility (:internal or :external)',
            optional: true,
            type: Symbol,
            verify_block: proc do |value|
              UI.user_error!("Visibility must be one of: #{VALID_VISIBILITIES.map { "`:#{_1}`" }.join(', ')}") unless VALID_VISIBILITIES.include?(value.to_s.downcase.to_sym)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: 'Filter builds by version string (e.g., "v1.7.5") — client-side filter matching version taxonomy keys',
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
            visibility: :internal,
            version: "v1.7.5"
          )',
        ]
      end
    end
  end
end
