module Fastlane
  module Actions
    class AndroidDownloadFileByVersionAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_localize_helper'
        require_relative '../../helper/github_helper'

        version = Fastlane::Helper::Android::VersionHelper.get_library_version_from_gradle_config(import_key: params[:import_key])
        UI.user_error!("Can't find any reference for key #{params[:import_key]}") if version.nil?
        UI.message "Downloading #{params[:file_path]} from #{params[:repository]} at version #{version} to #{params[:download_folder]}"

        access_token = params[:access_token]
        github_helper = Fastlane::Helper::GithubHelper.new(github_token: access_token)

        github_helper.download_file_from_tag(
          repository: params[:repository],
          tag: "#{params[:github_release_prefix]}#{version}",
          file_path: params[:file_path],
          download_folder: params[:download_folder]
        )
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Downloads a file from a GitHub release based on the version used by the client app'
      end

      def self.details
        'This action extracts the version of the library which is imported by the client app' \
          'and downloads the request file from the relevant GitHub release'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :library_name,
                                       description: 'The display name of the library',
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :import_key,
                                       description: 'The key which is used in build.gradle to reference the version of the library to import',
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :repository,
                                       description: "The GitHub repository slug ('<orgname>/<reponame>') which hosts the library project",
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       description: 'The path of the file to download',
                                       type: String,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :download_folder,
                                       description: 'The download folder',
                                       type: String,
                                       optional: true,
                                       default_value: Dir.tmpdir()),
          FastlaneCore::ConfigItem.new(key: :github_release_prefix,
                                       description: 'The prefix which is used in the GitHub release title',
                                       type: String,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :access_token,
                                       env_name: 'GITHUB_TOKEN',
                                       description: 'The GitHub OAuth access token',
                                       optional: false,
                                       default_value: false,
                                       type: String),
        ]
      end

      def self.output
      end

      def self.return_value
        'The path where the file was downloaded to (typically <download_folder>/<basename(file_path)>), or nil if there was an issue downloading the file'
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
