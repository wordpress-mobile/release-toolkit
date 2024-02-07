require_relative '../../helper/ios/ios_adc_app_sizes_helper'

module Fastlane
  module Actions
    class IosGetStoreAppSizesAction < Action
      Helper = Fastlane::Helper::Ios::ADCAppSizesHelper

      def self.run(params)
        app_sizes = Helper.get_adc_sizes(
          adc_user: params[:adc_user],
          adc_team: params[:adc_team],
          bundle_id: params[:bundle_id],
          only_version: params[:version],
          limit: params[:limit]
        )

        devices = params[:devices]

        case params[:format]
        when 'csv'
          csv = Helper.format_csv(app_sizes, devices: devices)
          UI.message "Result (CSV)\n\n#{csv}\n"
        when 'markdown'
          tables = Helper.format_markdown(app_sizes, devices: devices)
          tables.each do |table|
            UI.message "Result (Markdown)\n\n#{table}\n"
          end
        end

        app_sizes
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Gets the size of the app as reported in Apple Developer Portal for recent versions'
      end

      def self.details
        'Gets the download + installed size of the app from the Apple Developer Portail for various app versions release to AppStore and various device types'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :adc_user,
            env_name: 'FL_IOS_STOREAPPSIZES_USER',
            description: 'The ADC user to use to log into ADC',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :adc_team,
            env_name: 'FL_IOS_STOREAPPSIZES_TEAM',
            description: 'The ADC team name to use to log into ADC',
            type: String,
            optional: true,
            default_value: 'Automattic, Inc.'
          ),
          FastlaneCore::ConfigItem.new(
            key: :bundle_id,
            env_name: 'FL_IOS_STOREAPPSIZES_BUNDLEID',
            description: 'The bundleID of the app to retrieve sizes from',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            env_name: 'FL_IOS_STOREAPPSIZES_VERSION',
            description: 'The version to retrive the data for. Keep nil to retrieve data for all the last {limit} versions',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :limit,
            env_name: 'FL_IOS_STOREAPPSIZES_LIMIT',
            description: 'The maximum number of past versions to retrieve information from',
            type: Integer,
            optional: true,
            default_value: 10
          ),
          FastlaneCore::ConfigItem.new(
            key: :devices,
            env_name: 'FL_IOS_STOREAPPSIZES_DEVICES',
            description: 'The list of devices to print the app size for. If nil, will print data for all device types returned by ADC',
            type: Array,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :format,
            env_name: 'FL_IOS_STOREAPPSIZES_FORMAT',
            description: "The output format used to print the result. Can be one of 'csv' or 'markdown', or nil to print nothing (raw data will always be available as the the action's return value)",
            type: String,
            optional: true
          ),
        ]
      end

      def self.output
        # Define the shared values you are going to provide
      end

      def self.return_type
        :hash
      end

      def self.return_value
        'Return a Hash containing the details of download and install app size, for various device models, all that for each requested version of the app'
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['Automattic']
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end
    end
  end
end
