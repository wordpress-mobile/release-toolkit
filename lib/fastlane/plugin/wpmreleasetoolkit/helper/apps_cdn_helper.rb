# frozen_string_literal: true

require 'uri'

module Fastlane
  module Helper
    module AppsCdnHelper
      API_BASE_URL = 'https://public-api.wordpress.com'

      # See https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-visibility.php
      VALID_VISIBILITIES = %i[internal external].freeze

      # These are from the WordPress.com API, not the Apps CDN plugin
      VALID_POST_STATUS = %w[publish draft].freeze

      # Builds a WordPress.com REST API v1.1 URI scoped to a site.
      #
      # @param site_id [String] the WordPress.com site ID
      # @param path [String] the API path relative to the site (e.g. 'media/new')
      # @return [URI] the parsed full API URI
      def self.rest_v1_1_url(site_id:, path:)
        URI.parse("#{API_BASE_URL}/rest/v1.1/sites/#{site_id}/#{path}")
      end

      # Builds a WordPress.com REST API wpcom/v2 URI scoped to a site.
      #
      # @param site_id [String] the WordPress.com site ID
      # @param path [String] the API path relative to the site (e.g. 'a8c-cdn/builds/123')
      # @return [URI] the parsed full API URI
      def self.wpcom_v2_url(site_id:, path:)
        URI.parse("#{API_BASE_URL}/wpcom/v2/sites/#{site_id}/#{path}")
      end

      # Returns a proc that validates a visibility parameter value against {VALID_VISIBILITIES}.
      # Intended for use as a `verify_block` in Fastlane ConfigItem definitions.
      #
      # @return [Proc] a proc that raises FastlaneError if the value is invalid
      def self.verify_visibility_param
        proc do |value|
          UI.user_error!("Visibility must be one of: #{VALID_VISIBILITIES.map { "`:#{_1}`" }.join(', ')}") unless VALID_VISIBILITIES.include?(value.to_s.downcase.to_sym)
        end
      end

      # Returns a proc that validates a post status parameter value against {VALID_POST_STATUS}.
      # Intended for use as a `verify_block` in Fastlane ConfigItem definitions.
      #
      # @return [Proc] a proc that raises FastlaneError if the value is invalid
      def self.verify_post_status_param
        proc do |value|
          UI.user_error!("Post status must be one of: #{VALID_POST_STATUS.join(', ')}") unless VALID_POST_STATUS.include?(value)
        end
      end
    end
  end
end
