require 'fastlane/action'
require 'rubygems/command_manager'

module Fastlane
  module Actions
    class CheckForToolkitUpdatesAction < Action
      TOOLKIT_SPEC_NAME = 'fastlane-plugin-wpmreleasetoolkit'.freeze

      def self.run(params)
        updater = Gem::CommandManager.instance[:update]
        installed_gems = updater.highest_installed_gems.select { |spec| spec == TOOLKIT_SPEC_NAME }
        local_version = Gem::Version.new(installed_gems[TOOLKIT_SPEC_NAME].version)
        updates_needed = updater.which_to_update(installed_gems, [TOOLKIT_SPEC_NAME])

        if updates_needed.empty?
          UI.success("The release toolkit is up-to-date (#{local_version})! ✅")
          return
        end

        # Return type of which_to_update differs before/after RubyGems 3.1.0, so normalize to always use Gem::NameTuple
        updates_needed = Gem::NameTuple.from_list(updates_needed)
        latest_toolkit_version = updates_needed.find { |gem_info| gem_info.name == TOOLKIT_SPEC_NAME }.version

        UI.important("There is a new version #{latest_toolkit_version.to_s.yellow} of the release toolkit (you are using #{local_version.to_s.yellow}")

        return if params[:skip_update_suggestion]
        return unless UI.interactive? && UI.confirm('Do you want to update the toolkit now?')

        sh('bundle', 'update', TOOLKIT_SPEC_NAME)
        UI.abort_with_message!("#{TOOLKIT_SPEC_NAME} have been updated. Please check and commit the changes in your Gemfile.lock file, then restart your previous invocation of fastlane to use the new toolkit.")
      end

      def self.description
        'Check that we are on the latest version of the release toolkit and propose to update if not.'
      end

      def self.authors
        ['Olivier Halligon']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Sets the 'release branch' protection state for the specified branch"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_update_suggestion,
                                       env_name: 'CHECK_FOR_TOOLKIT_UPDATES_SKIP_UPDATE_SUGGESTION',
                                       description: 'If true, will still check for new versions, but will not ask if you want to run bundle update if an update is found',
                                       is_string: false, # Boolean
                                       default_value: false),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
