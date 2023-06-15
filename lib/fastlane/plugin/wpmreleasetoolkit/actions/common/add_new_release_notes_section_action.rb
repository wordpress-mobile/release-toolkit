module Fastlane
  module Actions
    class IosUpdateReleaseNotesAction < Action
      def self.run(params)
        UI.message 'Adding a new section to the release notes for the next version...'

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/ios/ios_version_helper'
        require_relative '../../helper/release_notes_helper'
        require_relative '../../helper/git_helper'

        path = params[:release_notes_file_path]
        
        if params[:new_version] == ':ios' || 'mac'
          next_version = Fastlane::Helper::Ios::VersionHelper.calc_next_release_version(params[:new_version])
        elsif params[:new_version] == ':android'
            next_version = Fastlane::Helper::Android::VersionHelper.calc_next_release_short_version(params[:new_version])
        else
          UI.message 'Please specify the platform of the app'
        end

        Fastlane::Helper::ReleaseNotesHelper.add_new_section(
          path: path,
          section_title: next_version
        )
#        Fastlane::Helper::GitHelper.commit(
#          message: "Release Notes: add new section for next version (#{next_version})",
#          files: path
#        )

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Adds a new section to the release notes file for the next app version'
      end

      def self.details
        'Adds a new section to the release notes file for the next app version'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: 'FL_ADD_NEW_RELEASE_NOTES_SECTION_PLATFORM',
                                       description: 'The version we are currently freezing. An empty entry for the _next_ version after this one will be added to the release notes',
                                       default_value: runner.current_platform
                                       type: Symbol),
          FastlaneCore::ConfigItem.new(key: :new_version,
                                       env_name: 'FL_ADD_NEW_RELEASE_NOTES_SECTION_VERSION',
                                       description: 'The version we are currently freezing. An empty entry for the _next_ version after this one will be added to the release notes',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path,
                                       env_name: 'FL_ADD_NEW_RELEASE_NOTES_SECTION_FILE_PATH',
                                       description: 'The path to the release notes file to be updated',
                                       type: String,
                                       default_value: File.join(ENV['PROJECT_ROOT_FOLDER'] || '.', 'RELEASE-NOTES.txt')),
        ]
      end

      def self.output
      end

      def self.return_value
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
