require 'json'
require 'net/http'
require 'zlib'

module Fastlane
  module WPMRT
    # A helper class to build an App Size Metrics payload and send it to a server (or write it to disk)
    #
    # The payload generated (and sent) by this helper conforms to the API for grouped metrics described in
    # https://github.com/Automattic/apps-metrics
    #
    class AppSizeMetricsHelper
      # @param [Hash] group_meta Metadata common to all the metrics. Can be any arbitrary set of key/value pairs.
      #
      def initialize(group_meta = {})
        self.meta = group_meta
        @metrics = []
      end

      # Sets the metadata common to the whole group of metrics in the payload being built by this helper instance
      #
      # @param [Hash] hash The metadata common to all the metrics of the payload built by that helper instance. Can be any arbitrary set of key/value pairs
      #
      def meta=(hash)
        @meta = (hash.compact || {}).map { |key, value| { name: key.to_s, value: value } }
      end

      # Adds a single metric to the group of metrics
      #
      # @param [String] name The metric name
      # @param [Integer] value The metric value
      # @param [Hash] meta The arbitrary dictionary of metadata to associate to that metric entry
      #
      def add_metric(name:, value:, meta: nil)
        metric = { name: name, value: value }
        meta = (meta || {}).compact # Remove nil values if any
        metric[:meta] = meta.map { |meta_key, meta_value| { name: meta_key.to_s, value: meta_value } } unless meta.empty?
        @metrics.append(metric)
      end

      def to_h
        {
          meta: @meta,
          metrics: @metrics
        }
      end

      # Send the metrics to the given App Metrics endpoint.
      #
      # Must conform to the API described in https://github.com/Automattic/apps-metrics/wiki/Queue-Group-of-Metrics
      #
      # @param [String,URI] to The URL of the App Metrics service, or a `file://` URL to write the payload to disk
      # @param [String] api_token The API bearer token to use to register the metric.
      # @return [Integer] the HTTP response code
      #
      def send_metrics(to:, api_token:, use_gzip: true)
        uri = URI(to)
        json_payload = use_gzip ? Zlib.gzip(to_h.to_json) : to_h.to_json

        # Allow using a `file:` URI for debugging
        if uri.is_a?(URI::File)
          UI.message("Writing metrics payload to file #{uri.path} (instead of sending it to a server)")
          File.write(uri.path, json_payload)
          return 201 # To make it easy at call site to check for pseudo-status code 200 even in non-HTTP cases
        end

        UI.message("Sending metrics to #{uri}...")
        headers = {
          Authorization: "Bearer #{api_token}",
          Accept: 'application/json',
          'Content-Type': 'application/json'
        }
        headers[:'Content-Encoding'] = 'gzip' if use_gzip

        request = Net::HTTP::Post.new(uri, headers)
        request.body = json_payload

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          UI.success("Metrics sent. (#{response.code} #{response.message})")
        else
          UI.error("Metrics failed to send. Received: #{response.code} #{response.message}")
          UI.message("Request was #{request.method} to #{request.uri}")
          UI.message("Request headers were: #{headers}")
          UI.message("Request body was #{request.body.length} bytes")
          UI.message("Response was #{response.body}")
        end
        response.code.to_i
      end
    end
  end
end
