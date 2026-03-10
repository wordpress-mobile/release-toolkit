# frozen_string_literal: true

module Fastlane
  module Helper
    module AppsCdnHelper
      API_BASE_URL = 'https://public-api.wordpress.com'

      # See https://github.a8c.com/Automattic/wpcom/blob/trunk/wp-content/lib/a8c/cdn/src/enums/enum-visibility.php
      VALID_VISIBILITIES = %i[internal external].freeze

      # These are from the WordPress.com API, not the Apps CDN plugin
      VALID_POST_STATUS = %w[publish draft].freeze

      # Builds a WordPress.com REST API v1.1 URL scoped to a site.
      #
      # @param site_id [String] the WordPress.com site ID
      # @param path [String] the API path relative to the site (e.g. 'media/new')
      # @return [String] the full API URL
      def self.rest_v1_1_url(site_id:, path:)
        "#{API_BASE_URL}/rest/v1.1/sites/#{site_id}/#{path}"
      end

      # Builds a WordPress.com WP REST API v2 URL scoped to a site.
      #
      # @param site_id [String] the WordPress.com site ID
      # @param path [String] the API path relative to the site (e.g. 'a8c_cdn_build/123')
      # @return [String] the full API URL
      def self.wp_v2_url(site_id:, path:)
        "#{API_BASE_URL}/wp/v2/sites/#{site_id}/#{path}"
      end
    end
  end
end
