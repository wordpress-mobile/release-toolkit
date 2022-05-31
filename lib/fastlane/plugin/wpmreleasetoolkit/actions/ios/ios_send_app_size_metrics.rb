require 'plist'
require_relative '../../helper/app_size_metrics_helper'

module Fastlane
  module Actions
    class IosSendAppSizeMetricsAction < Action
      def self.run(params)
        # Check input parameters
        api_url = URI(params[:api_url])
        api_token = params[:api_token]
        if (api_token.nil? || api_token.empty?) && !api_url.is_a?(URI::File)
          UI.user_error!('An API token is required when using an `api_url` with a scheme other than `file://`')
        end

        # Build the payload base
        metrics_helper = Fastlane::Helper::AppSizeMetricsHelper.new(
          Platform: 'iOS',
          'App Name': params[:app_name],
          'App Version': params[:app_version],
          'Build Type': params[:build_type],
          Source: params[:source]
        )
        metrics_helper.add_metric(name: 'File Size', value: File.size(params[:ipa_path]))

        # Add app-thinning metrics to the payload if a `.plist` is provided
        app_thinning_plist_path = params[:app_thinning_plist_path] || File.join(File.dirname(params[:ipa_path]), 'app-thinning.plist')
        if File.exist?(app_thinning_plist_path)
          plist = Plist.parse_xml(app_thinning_plist_path)
          plist['variants'].each do |_key, variant|
            variant_descriptors = variant['variantDescriptors'] || [{ 'device' => 'Universal' }]
            variant_descriptors.each do |desc|
              variant_metadata = { device: desc['device'], 'OS Version': desc['os-version'] }
              metrics_helper.add_metric(name: 'Download Size', value: variant['sizeCompressedApp'], metadata: variant_metadata)
              metrics_helper.add_metric(name: 'Install Size', value: variant['sizeUncompressedApp'], metadata: variant_metadata)
            end
          end
        end

        # Send the payload
        metrics_helper.send_metrics(
          to: api_url,
          api_token: api_token,
          use_gzip: params[:use_gzip_content_encoding]
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Send iOS app size metrics to our metrics server'
      end

      def self.details
        <<~DETAILS
          Send iOS app size metrics to our metrics server.

          In order to get Xcode generate the `app-thinning.plist` file (during `gym` and the export of the `.xcarchive`), you need to:
            (1) Use either `ad-hoc`, `enterprise` or `development` export method (in particular, won't work with `app-store`),
            (2) Provide `thinning: '<thin-for-all-variants>'` as part of your `export_options` of `gym` (or in your `options.plist` file if you use raw `xcodebuild`)
          See https://help.apple.com/xcode/mac/11.0/index.html#/devde46df08a

          For builds exported with the `app-store` method, `xcodebuild` won't generate an `app-thinning.plist` file; so you will only be able to get
          the Universal `.ipa` file size as a metric, but won't get the per-device, broken-down install and download sizes for each thinned variant.

          See https://github.com/Automattic/apps-metrics for the API contract expected by the Metrics server you are expected to send those metrics to.

          Tip: If you provide a `file://` URL for the `api_url`, the action will write the payload on disk at the specified path instead of sending
          the data to a endpoint over network. This can be useful e.g. to inspect the payload and debug it, or to store the metrics data as CI artefacts.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :api_url,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_API_URL',
            description: 'The endpoint API URL to publish metrics to. (Note: you can also point to a `file://` URL to write the payload to a file instead)',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_token,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_API_TOKEN',
            description: 'The bearer token to call the API. Required, unless `api_url` is a `file://` URL',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :use_gzip_content_encoding,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_USE_GZIP_CONTENT_ENCODING',
            description: 'Specify that we should use `Content-Encoding: gzip` and gzip the body when sending the request',
            type: FastlaneCore::Boolean,
            default_value: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_name,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_APP_NAME',
            description: 'The name of the app for which we are publishing metrics, to help with filtering and grouping',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_version,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_APP_VERSION',
            description: 'The version of the app for which we are publishing metrics, to help with filtering and grouping',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_type,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_BUILD_TYPE',
            description: 'The build configuration for which we are publishing metrics, to help with filtering and grouping. E.g. `Debug`, `Release`',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :source,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_SOURCE',
            description: 'The type of event at the origin of that build, to help with filtering and grouping. E.g. `pr`, `beta`, `final-release`',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :ipa_path,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_IPA_PATH',
            description: 'The path to the `.ipa` to extract size information from',
            type: String,
            optional: false,
            default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
            verify_block: proc do |value|
              UI.user_error!('You must provide an path to an existing `.ipa` file') unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_thinning_plist_path,
            env_name: 'FL_IOS_SEND_APP_SIZE_METRICS_APP_THINNING_PLIST_PATH',
            description: 'The path to the `app-thinning.plist` file to extract thinning size information from. ' \
              + 'By default, will try to use the `app-thinning.plist` file next to the `ipa_path`, if that file exists',
            type: String,
            optional: true,
            default_value_dynamic: true
          ),
        ]
      end

      def self.return_type
        :integer
      end

      def self.return_value
        'The HTTP return code from the call. Expect a 201 when new metrics were received successfully and entries created in the database'
      end

      def self.authors
        ['automattic']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
