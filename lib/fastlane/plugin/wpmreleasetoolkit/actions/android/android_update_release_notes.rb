# frozen_string_literal: true

module Fastlane
  module Actions
    class AndroidUpdateReleaseNotesAction < Action
      def self.run(params)
        UI.message 'Updating the release notes...'

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/release_notes_helper'
        require_relative '../../helper/git_helper'

        UI.user_error!('You must provide a non-empty value for either `next_version` or `new_version`') if params[:next_version].to_s.strip.empty? && params[:new_version].to_s.strip.empty?

        path = params[:release_notes_file_path]
        next_version = params[:next_version]&.strip
        next_version = Fastlane::Helper::Android::VersionHelper.calc_next_release_short_version(params[:new_version]) if next_version.nil? || next_version.empty?

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
                                       deprecated: 'Deprecated in favor of `next_version`. ' \
                                                   'The `new_version` parameter computes the next version using a built-in calculator ' \
                                                   'that assumes the minor version rolls over to the next major at 9, which is incorrect for apps using semantic versioning',
                                       optional: true,
                                       conflicting_options: [:next_version],
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :next_version,
                                       description: 'The next version to use as the section title in the release notes. ' \
                                                    'This value is used directly as the section title. ' \
                                                    'Use this if your app does not follow the default versioning convention (minor capped at 9)',
                                       optional: true,
                                       conflicting_options: [:new_version],
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path,
                                       env_name: 'FL_ANDROID_UPDATE_RELEASE_NOTES_FILE_PATH',
                                       description: 'The path to the release notes file to be updated',
                                       type: String,
                                       default_value: 'RELEASE-NOTES.txt'),
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
