# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'json'
require_relative '../../helper/apps_cdn_helper'

module Fastlane
  module Actions
    class UpdateAppsCdnBuildMetadataAction < Action
      def self.run(params)
        post_ids = params[:post_ids]
        UI.message("Updating Apps CDN build metadata for #{post_ids.size} post(s): #{post_ids.join(', ')}...")

        # Build the base JSON body for the WP REST API v2
        body = {}
        body['status'] = params[:post_status] if params[:post_status]

        if params[:visibility]
          term_id = lookup_visibility_term_id(site_id: params[:site_id], api_token: params[:api_token], visibility: params[:visibility])
          body['visibility'] = [term_id]
        end

        UI.user_error!('No metadata to update. Provide at least one of: visibility, post_status') if body.empty?

        results = post_ids.map do |post_id|
          update_single_post(site_id: params[:site_id], api_token: params[:api_token], post_id: post_id, body: body)
        end

        UI.success("Successfully updated Apps CDN build metadata for #{results.size} post(s)")
        results
      end

      # Update a single CDN build post with the given body via the WP REST API v2.
      #
      # @param site_id [String] the WordPress.com site ID
      # @param api_token [String] the WordPress.com API bearer token
      # @param post_id [Integer] the ID of the post to update
      # @param body [Hash] the JSON body to send in the POST request
      # @return [Integer] the ID of the updated post
      # @raise [FastlaneCore::Interface::FastlaneError] if the API returns a non-success response
      def self.update_single_post(site_id:, api_token:, post_id:, body:)
        uri = Helper::AppsCdnHelper.wp_v2_url(site_id: site_id, path: "a8c_cdn_build/#{post_id}")

        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = JSON.generate(body)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        request['Authorization'] = "Bearer #{api_token}"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.open_timeout = 10
          http.read_timeout = 30
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          result = JSON.parse(response.body)
          updated_id = result['id']

          UI.message("  Updated post #{updated_id}")

          updated_id
        else
          UI.error("Failed to update Apps CDN build metadata for post #{post_id}: #{response.code} #{response.message}")
          UI.error(response.body)
          UI.user_error!("Update of Apps CDN build metadata failed for post #{post_id}")
        end
      end

      # Look up the taxonomy term ID for a visibility value (e.g. :internal -> 1316).
      #
      # @param site_id [String] the WordPress.com site ID
      # @param api_token [String] the WordPress.com API bearer token
      # @param visibility [Symbol] the visibility to look up (:internal or :external)
      # @return [Integer] the taxonomy term ID for the given visibility
      # @raise [FastlaneCore::Interface::FastlaneError] if no term is found or the API returns a non-success response
      def self.lookup_visibility_term_id(site_id:, api_token:, visibility:)
        slug = visibility.to_s.downcase
        uri = Helper::AppsCdnHelper.wp_v2_url(site_id: site_id, path: "visibility?slug=#{slug}")

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
          UI.user_error!("No visibility term found for '#{slug}'") if terms.empty?
          terms.first['id']
        else
          UI.user_error!("Failed to look up visibility term '#{slug}': #{response.code} #{response.message}")
        end
      end

      def self.description
        'Updates metadata of one or more existing builds on the Apps CDN'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns an Array of post IDs (Integer) that were successfully updated. On error, raises a FastlaneError.'
      end

      def self.details
        <<~DETAILS
          Updates metadata (such as post status or visibility) for one or more existing build posts on a WordPress blog
          that has the Apps CDN plugin enabled, using the WordPress.com REST API (WP v2).
          When updating visibility for multiple posts, the visibility term ID is looked up only once.
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
            key: :post_ids,
            description: 'The IDs of the build posts to update',
            optional: false,
            type: Array,
            verify_block: proc do |value|
              UI.user_error!('Post IDs must be a non-empty array') unless value.is_a?(Array) && !value.empty?
              value.each do |id|
                UI.user_error!("Each post ID must be a positive integer, got: #{id.inspect}") unless id.is_a?(Integer) && id.positive?
              end
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
            verify_block: Helper::AppsCdnHelper.verify_visibility
          ),
          FastlaneCore::ConfigItem.new(
            key: :post_status,
            description: "The new post status ('publish' or 'draft')",
            optional: true,
            type: String,
            verify_block: Helper::AppsCdnHelper.verify_post_status
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
            post_ids: [98765],
            post_status: "publish"
          )',
          'update_apps_cdn_build_metadata(
            site_id: "12345678",
            api_token: ENV["WPCOM_API_TOKEN"],
            post_ids: [12345, 67890, 11111],
            visibility: :external
          )',
        ]
      end
    end
  end
end
