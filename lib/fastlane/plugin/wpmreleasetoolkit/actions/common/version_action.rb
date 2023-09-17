module Fastlane
  module Actions
    class VersionAction < Action
      def self.run(params)
        require_relative '../../formatters/version_formatter'
        require_relative '../../formatters/ios_version_formatter'
        require_relative '../../formatters/android_version_formatter'

        platform = params[:app_platform]
        type = params[:version_type]
        version_object = params[:version_object]
        version = ''

        if type == 'release'
          version = Fastlane::Formatters::VersionFormatter.new(version_object).release_version
        else
          case platform
          when ':android'
            case type
            when 'beta'
              version = Fastlane::Formatters::AndroidVersionFormatter.new(version_object).beta_version
            else
              UI.user_error!('No version type found. Please include a version type and try again.')
            end
          when ':ios', ':mac'
            case type
            when 'beta'
              version = Fastlane::Formatters::IosVersionFormatter.new(version_object).beta_version
            when 'internal'
              version = Fastlane::Formatters::IosVersionFormatter.new(version_object).internal_version
            else
              UI.user_error!('No version type found. Please include a version type and try again.')
            end
          else
            UI.user_error!('No platform found. Please include the app platform and try again: `:android`, `:ios`, or `:mac`')
          end
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
                                       env_name: 'FL_APP_PLATFORM',
                                       description: 'The platform of the requested version number. Options are `:mac`, `:ios`, or `:android`',
                                       optional: false,
                                       type: String,
                                       default_value: Fastlane::Helper::LaneHelper.current_platform),
          FastlaneCore::ConfigItem.new(key: :version_type,
                                       env_name: 'FL_VERSION_TYPE',
                                       description: 'The type of version or version part being requested. Options are `release`, `beta`, or `internal`',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :version_object,
                                       env_name: 'FL_VERSION_OBJECT',
                                       description: 'The version object passed in from `read_version_from_file_action`',
                                       optional: true,
                                       is_string: false),
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
