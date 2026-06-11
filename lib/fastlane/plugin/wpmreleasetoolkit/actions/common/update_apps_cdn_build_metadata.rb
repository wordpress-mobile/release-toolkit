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

        # Build the JSON body for the dedicated Apps CDN builds endpoint, which accepts
        # the same string-based format as the upload flow (e.g. `visibility: 'Internal'`)
        body = {}
        body['post_status'] = params[:post_status] if params[:post_status]
        body['visibility'] = params[:visibility].to_s.capitalize if params[:visibility]

        UI.user_error!('No metadata to update. Provide at least one of: visibility, post_status') if body.empty?

        results = post_ids.map do |post_id|
          update_single_post(site_id: params[:site_id], api_token: params[:api_token], post_id: post_id, body: body)
        end

        UI.success("Successfully updated Apps CDN build metadata for #{results.size} post(s)")
        results
      end

      # Update a single CDN build post with the given body via the dedicated
      # `/wpcom/v2/sites/{site_id}/a8c-cdn/builds/{post_id}` endpoint.
      #
      # @param site_id [String] the WordPress.com site ID
      # @param api_token [String] the WordPress.com API bearer token
      # @param post_id [Integer] the ID of the build post to update
      # @param body [Hash] the JSON body to send in the POST request
      # @return [Integer] the ID of the updated post
      # @raise [FastlaneCore::Interface::FastlaneError] if the API returns a non-success response
      def self.update_single_post(site_id:, api_token:, post_id:, body:)
        uri = Helper::AppsCdnHelper.wpcom_v2_url(site_id: site_id, path: "a8c-cdn/builds/#{post_id}")

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
          that has the Apps CDN plugin enabled, using the dedicated `/wpcom/v2/sites/{site_id}/a8c-cdn/builds/{post_id}`
          endpoint. Standard WP REST API writes are blocked for builds, so this endpoint is the only way to update them.
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
            verify_block: Helper::AppsCdnHelper.verify_visibility_param
          ),
          FastlaneCore::ConfigItem.new(
            key: :post_status,
            description: "The new post status ('publish' or 'draft')",
            optional: true,
            type: String,
            verify_block: Helper::AppsCdnHelper.verify_post_status_param
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
