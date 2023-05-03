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
        UI.message("Currently using release toolkit version #{local_version.to_s.yellow}.")
        UI.message('Checking for updates now...')
        updates_needed = updater.which_to_update(installed_gems, [TOOLKIT_SPEC_NAME])

        if updates_needed.empty?
          UI.success('Your release toolkit is up-to-date! ✅')
          return nil
        end

        # Return type of which_to_update differs before/after RubyGems 3.1.0, so normalize to always use Gem::NameTuple
        updates_needed = Gem::NameTuple.from_list(updates_needed)
        latest_version = updates_needed.find { |gem_info| gem_info.name == TOOLKIT_SPEC_NAME }.version

        UI.message(['There is a newest version '.yellow, latest_version.to_s.red, ' of the release toolkit!'.yellow].join)
        warn_on_breaking_update(local_version, latest_version)

        return latest_version if params[:skip_update_suggestion] || !UI.confirm('Do you want to run bundle update now?')

        sh('bundle', 'update', TOOLKIT_SPEC_NAME)
        UI.abort_with_message! <<~UPDATE_MESSAGE
          #{TOOLKIT_SPEC_NAME} have been updated. Please check and commit the changes in your Gemfile.lock file,
          then restart your previous invocation of fastlane to use the new toolkit.
        UPDATE_MESSAGE
      end

      def self.warn_on_breaking_update(current_version, latest_version)
        current_semver_requirement = Gem::Requirement.new(current_version.approximate_recommendation)
        compatible_update = current_semver_requirement.satisfied_by?(latest_version)
        return if compatible_update

        new_semver_requirement = latest_version.approximate_recommendation
        UI.important <<~BREAKING_CHANGE_MESSAGE
          The latest version available (#{latest_version}) introduces breaking changes compared to the #{current_version} you are currently using.

           - To update to #{latest_version}, first edit your `Pluginfile` to use '#{new_semver_requirement}', run `bundle update`,
             then be sure to make all the necessary changes to your `Fastfile` (see the toolkit's CHANGELOG)
             to take those breaking changes into account.

           - If you are not ready to make the major version bump, you can still try to update to the latest compatible,
             non-breaking version by running `bundle update` now. This will not update to the latest #{latest_version}, but
             might still update to a newer version compatible with '#{current_semver_requirement}' if one exists; which is still valuable
             to at least get bugfixes, until you are ready to jump to the next major version later.
        BREAKING_CHANGE_MESSAGE
      end

      def self.description
        'Check that we are on the latest version of the release toolkit, and propose to update if not'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'Returns the latest version of the toolkit available if your toolkit is not up-to-date, or nil if you are already up-to-date.'
      end

      def self.details
        <<~DETAILS
          Check that we are on the latest version of the release toolkit, and propose to update if not.

          This action will check if you are on the *latest* version, regardless of the version requirement restriction you might have
          set in your Gemfile/Pluginfile; which means that even if you agree to the prompt suggesting you to run bundle update, it might not
          actually end up updating to the *latest* version automatically (esp. if the latest introduces breaking changes).

          Note that if it finds an update and you then agree to the prompt and run bundle update, the action will abort your fastlane invocation
          after running bundle update. This will let you check and commit the changes, before restarting the lane by re-invoking fastlane.
          This is also needed to ensure fastlane loads the new toolkit version after update on second run.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_update_suggestion,
                                       env_name: 'CHECK_FOR_TOOLKIT_UPDATES_SKIP_UPDATE_SUGGESTION',
                                       description: 'If true, will still check for new versions, but will not ask if you want to run bundle update if an update is found',
                                       type: Boolean,
                                       default_value: false),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
