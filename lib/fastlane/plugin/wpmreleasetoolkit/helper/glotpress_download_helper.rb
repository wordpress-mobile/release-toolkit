# frozen_string_literal: true

require 'net/http'
require 'uri'

module Fastlane
  module Helper
    # A helper class to download files from GlotPress with proper error handling and retry mechanism
    class GlotPressDownloader
      AUTO_RETRY_SLEEP_TIME = 20
      MAX_AUTO_RETRY_ATTEMPTS = 30

      attr_reader :auto_retry, :auto_retry_attempt_counter

      # Initialize a new GlotPressDownloader
      #
      # @param [Boolean] auto_retry Whether to automatically retry on rate limiting (429 errors)
      #
      def initialize(auto_retry: false)
        @auto_retry = auto_retry
        @auto_retry_attempt_counter = 0
      end

      # Downloads data from GlotPress
      #
      # @param [String] url The URL to download from
      # @param [String] locale The locale being downloaded (for logging purposes)
      # @yield [String] The response body if the download was successful
      # @return The result of the block if provided, or true/false indicating success
      #
      def download(url, locale)
        @current_locale = locale # Store for error handling
        uri = URI(url)
        response = make_request(uri)
        result = nil
        success = handle_response(response: response, locale: locale, original_uri: uri) do |body|
          result = yield body if block_given?
        end
        block_given? ? result : success
      end

      private

      def make_request(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = Wpmreleasetoolkit::USER_AGENT
        http.request(request)
      rescue StandardError => e
        # Network errors, connection errors, etc.
        UI.error("Error downloading locale `#{@current_locale}` — #{e.message} (#{uri})")
        retry if !FastlaneCore::Helper.is_ci? && UI.confirm("Retry downloading `#{@current_locale}`?")
        nil
      end

      def handle_response(response:, locale:, original_uri:)
        return false if response.nil?

        case response.code
        when '200'
          UI.success("Successfully downloaded `#{locale}`.")
          # Reset counter on success
          @auto_retry_attempt_counter = 0
          yield response.body if block_given?
          true
        when '301', '302', '307', '308'
          # Follow the redirect
          UI.message("Received #{response.code} for `#{locale}`. Following redirect...")
          redirect_url = response['location']
          if redirect_url.nil?
            UI.error("Received #{response.code} but no location header found.")
            false
          else
            download(redirect_url, locale) { |body| yield body if block_given? }
          end
        when '429'
          # Rate limited
          handle_rate_limiting(locale: locale, uri: original_uri) do |body|
            yield body if block_given?
          end
        else
          # Unexpected status code (including 404, 500, etc.)
          status_line = "#{response.code} #{response.message}"
          UI.error("Error downloading locale `#{locale}` — #{status_line} (#{original_uri})")
          if !FastlaneCore::Helper.is_ci? && UI.confirm("Retry downloading `#{locale}`?")
            download(original_uri.to_s, locale) { |body| yield body if block_given? }
          else
            false
          end
        end
      end

      def handle_rate_limiting(locale:, uri:)
        if @auto_retry && @auto_retry_attempt_counter < MAX_AUTO_RETRY_ATTEMPTS
          UI.message("Received 429 for `#{locale}`. Auto retrying in #{AUTO_RETRY_SLEEP_TIME} seconds... (attempt #{@auto_retry_attempt_counter + 1}/#{MAX_AUTO_RETRY_ATTEMPTS})")
          sleep(AUTO_RETRY_SLEEP_TIME)
          @auto_retry_attempt_counter += 1
          download(uri.to_s, locale) { |body| yield body if block_given? }
        elsif !FastlaneCore::Helper.is_ci? && UI.confirm("Retry downloading `#{locale}` after receiving 429 from the API?")
          @auto_retry_attempt_counter = 0 # Reset counter when user manually retries
          download(uri.to_s, locale) { |body| yield body if block_given? }
        else
          UI.error("Abandoning `#{locale}` download as requested.")
          false
        end
      end
    end
  end
end
