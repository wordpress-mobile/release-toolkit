module Fastlane
  module Actions
    class VersionAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/ios/ios_version_helper'

        platform = params[:app_platform]
        type = params[:version_type]
        file_path = params[:version_file_path]
        version = ''

        case platform
        when ':android'
          case type
          when 'alpha'
            version = Fastlane::Helper::Android::VersionHelper.get_alpha_version
          when 'public'
            version = Fastlane::Helper::Android::VersionHelper.get_public_version
          when 'release'
            version = Fastlane::Helper::Android::VersionHelper.get_release_version
          else
            'No version type found. Please include a version type and try again.'
          end
        when ':ios', ':mac'
          case type
          when 'build_number'
            version = Fastlane::Helper::Ios::VersionHelper.read_build_number_from_config_file(file_path)
          when 'internal_build_version'
            version = Fastlane::Helper::Ios::VersionHelper.get_internal_version
          when 'public'
            version = Fastlane::Helper::Ios::VersionHelper.get_xcconfig_public_version(xcconfig_file: file_path)
          when 'public_build_version'
            version = Fastlane::Helper::Ios::VersionHelper.get_build_version
          else
            'No version type found. Please include a version type and try again.'
          end
        else
          'No platform found. Please include the app platform and try again: `:android`, `:ios`, or `:mac`'
        end

        version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Returns the specified version of the app'
      end

      def self.details
        'Returns the specified version of the app'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_platform,
                                       env_name: 'FL_VERSION_FILE_PATH',
                                       description: 'The platform of the requested version number. Options are `:mac`, `:ios`, or `:android`',
                                       optional: false,
                                       type: String,
                                       default_value: Fastlane::Helper::LaneHelper.current_platform),
          FastlaneCore::ConfigItem.new(key: :version_type,
                                       env_name: 'FL_VERSION_TYPE',
                                       description: 'The type of version or version part being requested. Examples include `release`, `alpha`, `build_number`',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :version_file_path,
                                       env_name: 'FL_VERSION_FILE_PATH',
                                       description: 'The file path where the version is stored. Usually `build.gradle` for Android or an `xcconfig` file for iOS and Mac',
                                       optional: true,
                                       type: String),

        ]
      end

      def self.return_value
        'Return the specified version of the app'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
