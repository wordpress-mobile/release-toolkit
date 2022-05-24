require_relative '../../helper/app_size_metrics_helper'

module Fastlane
  module Actions
    class AndroidSendAppSizeMetricsAction < Action
      def self.run(params)
        # Check input parameters
        api_url = URI(params[:api_url])
        api_token = params[:api_token]
        if (api_token.nil? || api_token.empty?) && !api_url.is_a?(URI::File)
          UI.user_error!('An API token is required when using an `api_url` with a scheme other than `file://`')
        end

        # Build the payload base
        metrics_helper = Fastlane::Helper::AppSizeMetricsHelper.new(
          Platform: 'Android',
          'App Name': params[:app_name],
          'App Version': params[:app_version_name],
          'Version Code': params[:app_version_code],
          'Product Flavor': params[:product_flavor],
          'Build Type': params[:build_type],
          Source: params[:source]
        )
        metrics_helper.add_metric(name: 'AAB File Size', value: File.size(params[:aab_path]))

        # Add device-specific 'splits' metrics to the payload if a `:include_split_sizes` is enabled
        if params[:include_split_sizes]
          check_bundletool_installed!
          apkanalyzer_bin = find_apkanalyzer_binary!
          UI.message("[App Size Metrics] Generating the various APK splits from #{params[:aab_path]}...")
          Dir.mktmpdir('release-toolkit-android-app-size-metrics') do |tmp_dir|
            Action.sh('bundletool', 'build-apks', '--bundle', params[:aab_path], '--output-format', 'DIRECTORY', '--output', tmp_dir)
            apks = Dir.glob('splits/*.apk', base: tmp_dir).map { |f| File.join(tmp_dir, f) }
            UI.message("[App Size Metrics] Generated #{apks.length} APKs.")

            apks.each do |apk|
              UI.message("[App Size Metrics] Computing file and download size of #{File.basename(apk)}...")
              split_name = File.basename(apk, '.apk')
              file_size = Action.sh(apkanalyzer_bin, 'apk', 'file-size', apk, print_command: false, print_command_output: false).chomp.to_i
              download_size = Action.sh(apkanalyzer_bin, 'apk', 'download-size', apk, print_command: false, print_command_output: false).chomp.to_i
              metrics_helper.add_metric(name: 'APK File Size', value: file_size, meta: { split: split_name })
              metrics_helper.add_metric(name: 'Download Size', value: download_size, meta: { split: split_name })
            end

            UI.message('[App Size Metrics] Done computing splits sizes.')
          end
        end

        # Send the payload
        metrics_helper.send_metrics(
          to: api_url,
          api_token: api_token,
          use_gzip: params[:use_gzip_content_encoding]
        )
      end

      def self.check_bundletool_installed!
        Action.sh('command', '-v', 'bundletool', print_command: false, print_command_output: false)
      rescue StandardError
        UI.user_error!('bundletool is required to build the split APKs. Install it with `brew install bundletool`')
        raise
      end

      def self.find_apkanalyzer_binary!
        sdk_root = ENV['ANDROID_SDK_ROOT'] || ENV['ANDROID_HOME']
        apkanalyzer_bin = sdk_root.nil? ? Action.sh('command', '-v', 'apkanalyzer') : File.join(sdk_root, 'cmdline-tools', 'latest', 'bin', 'apkanalyzer')
        UI.user_error!('Unable to find apkanalyzer executable. Make sure you installed the Android SDK Command-line Tools') unless File.executable?(apkanalyzer_bin)
        apkanalyzer_bin
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Send Android app size metrics to our metrics server'
      end

      def self.details
        <<~DETAILS
          Send Android app size metrics to our metrics server.

          See https://github.com/Automattic/apps-metrics for the API contract expected by the Metrics server you will send those metrics to.

          Tip: If you provide a `file://` URL for the `api_url`, the action will write the payload on disk at the specified path instead of sending
          the data to a endpoint over network. This can be useful e.g. to inspect the payload and debug it, or to store the metrics data as CI artefacts.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :api_url,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_API_URL',
            description: 'The endpoint API URL to publish metrics to. (Note: you can also point to a `file://` URL to write the payload to a file instead)',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_token,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_API_TOKEN',
            description: 'The bearer token to call the API. Required, unless `api_url` is a `file://` URL',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :use_gzip_content_encoding,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_USE_GZIP_CONTENT_ENCODING',
            description: 'Specify that we should use `Content-Encoding: gzip` and gzip the body when sending the request',
            type: FastlaneCore::Boolean,
            default_value: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_name,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_APP_NAME',
            description: 'The name of the app for which we are publishing metrics, to help filter by app in the dashboard',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_version_name,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_APP_VERSION_NAME',
            description: 'The version name of the app for which we are publishing metrics, to help filter by version in the dashboard',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_version_code,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_APP_VERSION_CODE',
            description: 'The version code of the app for which we are publishing metrics, to help filter by version in the dashboard',
            type: Integer,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :product_flavor,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_PRODUCT_FLAVOR',
            description: 'The product flavor for which we are publishing metrics, to help filter by flavor in the dashboard. E.g. `Vanilla`, `Jalapeno`, `Wasabi`',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_type,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_BUILD_TYPE',
            description: 'The build type for which we are publishing metrics, to help filter by build type in the dashboard. E.g. `Debug`, `Release`',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :source,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_SOURCE',
            description: 'The type of event at the origin of that build, to help filter data in the dashboard. E.g. `pr`, `beta`, `final-release`',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :aab_path,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_AAB_PATH',
            description: 'The path to the .aab to extract size information from',
            type: String,
            optional: false,
            verify_block: proc do |value|
              UI.user_error!('You must provide an path to an existing `.aab` file') unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :include_split_sizes,
            env_name: 'FL_ANDROID_SEND_APP_SIZE_METRICS_INCLUDE_SPLIT_SIZES',
            description: 'Indicate if we should use `bundletool` and `apkanalyzer` to also compute and send "split apk" sizes per architecture. ' \
              + 'Setting this to `true` adds a bit of extra time to generate the `.apk` and extract the data, but provides more detailed metrics',
            type: FastlaneCore::Boolean,
            default_value: true
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
        platform == :android
      end
    end
  end
end
