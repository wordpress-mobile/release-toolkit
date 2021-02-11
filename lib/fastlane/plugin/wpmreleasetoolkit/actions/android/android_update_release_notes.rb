module Fastlane
  module Actions
    class AndroidUpdateReleaseNotesAction < Action
      def self.run(params)
        UI.message 'Updating the release notes...'

        require_relative '../../helper/android/android_version_helper.rb'
        require_relative '../../helper/release_notes_helper.rb'
        require_relative '../../helper/git_helper.rb'

        path = File.join(ENV['PROJECT_ROOT_FOLDER'] || '.', 'RELEASE-NOTES.txt')
        next_version = Fastlane::Helper::Android::VersionHelper.calc_next_release_short_version(params[:new_version])

        Fastlane::Helper::ReleaseNotesHelper.add_new_section(path: path, section_title: next_version)
        Fastlane::Helper::GitHelper.commit(message: "Release Notes: add new section for next version (#{next_version})", files: path, push: true)

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
                                       is_string: true)
        ]
      end

      def self.output

      end

      def self.return_value

      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
  end
