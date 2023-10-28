module Fastlane
  module Actions
    class AndroidUpdateReleaseNotesAction < Action
      def self.run(params)
        UI.message 'Updating the release notes...'

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/release_notes_helper'
        require_relative '../../helper/git_helper'

        UI.deprecated('The `PROJECT_ROOT_FOLDER` environment variable is deprecated and will be removed in a future release. Please pass a path to the `release_notes_file_path` param instead.') unless ENV['PROJECT_ROOT_FOLDER'].nil?

        path = params[:release_notes_file_path]
        next_version = Fastlane::Helper::Android::VersionHelper.calc_next_release_short_version(params[:new_version])

        Fastlane::Helper::ReleaseNotesHelper.add_new_section(path: path, section_title: next_version)
        Fastlane::Helper::GitHelper.commit(message: "Release Notes: add new section for next version (#{next_version})", files: path)

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Updates the release notes file for the next app version'
      end

      def self.details
        'Updates the release notes file for the next app version'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :new_version,
                                       env_name: 'FL_ANDROID_UPDATE_RELEASE_NOTES_VERSION',
                                       description: 'The version we are currently freezing; An empty entry for the _next_ version after this one will be added to the release notes',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path,
                                       env_name: 'FL_ANDROID_UPDATE_RELEASE_NOTES_FILE_PATH',
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
        platform == :android
      end
    end
  end
end
