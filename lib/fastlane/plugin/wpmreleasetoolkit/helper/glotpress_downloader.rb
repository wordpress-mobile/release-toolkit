# frozen_string_literal: true

require 'net/http'
require 'uri'

module Fastlane
  module Helper
    # A helper class to download files from GlotPress with proper error handling and retry mechanism
    class GlotPressDownloader
      class DownloadError < StandardError; end

      AUTO_RETRY_SLEEP_TIME = 20
      MAX_AUTO_RETRY_ATTEMPTS = 30

      attr_reader :auto_retry, :auto_retry_attempt_counter, :url, :locale

      # Initialize a new GlotPressDownloader
      #
      # @param [String] url The URL to download from
      # @param [String] locale The locale being downloaded (for logging purposes)
      # @param [Boolean] auto_retry Whether to automatically retry on rate limiting (429 errors)
      #
      def initialize(url:, locale:, auto_retry: false)
        @url = url
        @locale = locale
        @auto_retry = auto_retry
        @auto_retry_attempt_counter = 0
      end

      # Convenience class method to download in a single call
      #
      # @param [String] url The URL to download from
      # @param [String] locale The locale being downloaded (for logging purposes)
      # @param [Boolean] auto_retry Whether to automatically retry on rate limiting (429 errors)
      # @yield [String] The response body if the download was successful
      # @return The result of the block if provided, or true if no block is provided
      # @raise [DownloadError] If the download fails after retry handling
      #
      #
      def self.download(url:, locale:, auto_retry: false, &)
        new(url: url, locale: locale, auto_retry: auto_retry).download(&)
      end

      # Downloads data from GlotPress
      #
      # @yield [String] The response body if the download was successful
      # @return The result of the block if provided, or true if no block is provided
      # @raise [DownloadError] If the download fails after retry handling
      #
      def download(&)
        @auto_retry_attempt_counter = 0 # Reset counter only at start of download
        download_from_url(@url, &)
      end

      private

      def download_from_url(url, &)
        uri = URI(url)
        response = make_request(uri)
        handle_response(response: response, url: url, original_uri: uri, &)
      end

      def make_request(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = Wpmreleasetoolkit::USER_AGENT
        http.request(request)
      rescue StandardError => e
        # Network errors, connection errors, etc.
        message = "Error downloading locale `#{@locale}` — #{e.message} (#{uri})"
        UI.error(message)
        retry if UI.interactive? && UI.confirm("Retry downloading `#{@locale}`?")
        raise DownloadError, message
      end

      def handle_response(response:, url:, original_uri:, &)
        case response.code
        when '200'
          UI.success("Successfully downloaded `#{@locale}`.")
          block_given? ? yield(response.body) : true
        when '301', '302', '307', '308'
          # Follow the redirect
          UI.message("Received #{response.code} for `#{@locale}`. Following redirect...")
          redirect_url = response['location']
          if redirect_url.nil?
            message = "Received #{response.code} for `#{@locale}` but no location header was found."
            UI.error(message)
            raise DownloadError, message
          else
            # Follow redirect with the new URL
            download_from_url(redirect_url, &)
          end
        when '429'
          # Rate limited
          handle_rate_limiting(url: url, response: response, &)
        else
          # Unexpected status code (including 404, 500, etc.)
          status_line = [response.code, response.message].compact.join(' ').strip
          message = "Error downloading locale `#{@locale}` — #{status_line} (#{original_uri})"
          UI.error(message)
          raise DownloadError, message unless UI.interactive? && UI.confirm("Retry downloading `#{@locale}`?")

          download_from_url(url, &)
        end
      end

      def handle_rate_limiting(url:, response:, &)
        if @auto_retry && @auto_retry_attempt_counter < MAX_AUTO_RETRY_ATTEMPTS
          UI.message("Received 429 for `#{@locale}`. Auto retrying in #{AUTO_RETRY_SLEEP_TIME} seconds... (attempt #{@auto_retry_attempt_counter + 1}/#{MAX_AUTO_RETRY_ATTEMPTS})")
          sleep(AUTO_RETRY_SLEEP_TIME)
          @auto_retry_attempt_counter += 1
          download_from_url(url, &)
        elsif UI.interactive? && UI.confirm("Retry downloading `#{@locale}` after receiving 429 from the API?")
          download_from_url(url, &)
        else
          UI.error("Abandoning `#{@locale}` download.")
          status_line = [response.code, response.message].compact.join(' ').strip
          raise DownloadError, "Error downloading locale `#{@locale}` — #{status_line} (#{url})"
        end
      end
    end
  end
end
