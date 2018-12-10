require 'fastlane/action'
require 'fastlane_core/ui/ui'
require 'fileutils'

require_relative '../../helper/filesystem_helper'
require_relative '../../helper/configure_helper'

module Fastlane
  module Actions
    class ConfigureApplyAction < Action
      def self.run(params = {})
        files_to_copy.each { |x|

            source = absolute_secret_store_path(x["file"])
            destination = absolute_project_path(x["destination"])

            if(params[:force])
                copy(source, destination)
            else
                copy_with_confirmation(source, destination)
            end
        }

        UI.success "Applied configuration"
      end

      ### Check with the user whether we should overwrite the file, if it exists
      ###
      def self.copy_with_confirmation(source, destination)

        unless File.file?(destination)
            self.copy(source, destination)
            return  # Don't continue if we were able to copy the file without conflict
        end

        if UI.confirm("Are sure you want to overwrite #{destination}?")

            if UI.confirm("Would you like to make a backup of #{destination} before overwriting?")
                extension = File.extname(destination)
                base = File.basename(Pathname.new(destination), extension)

                date_string = Time.now.strftime('%m-%d-%Y--%H-%M-%S')

                backup_path = base
                    .concat("-")            # Handy-dandy separator
                    .concat(date_string)    # date string to allow multiple backups
                    .concat(extension)      # and the original file extension
                    .concat(".bak")        # add the .bak file extension - easier to .gitignore
                    
                self.copy(destination, backup_path)
            end

            self.copy(source, destination)
        else
            UI.message "Skipping #{destination}"
        end
      end

      ### Copy the file at `source` to `destination`, overwriting it if it already exists
      ###
      def self.copy(source, destination)

        pn = Pathname.new(destination)

        FileUtils.mkdir_p(pn.dirname)   # Create the destination directory if it doesn't exist
        FileUtils.cp(source, destination)
      end

      def self.repository_path
        Fastlane::Helper::FilesystemHelper.secret_store_dir
      end

      def self.files_to_copy
        Fastlane::Helper::ConfigureHelper.files_to_copy
      end

      def self.absolute_project_path(relative_path)
        Fastlane::Helper::FilesystemHelper.absolute_project_path(relative_path)
      end

      def self.absolute_secret_store_path(relative_path)
        Fastlane::Helper::FilesystemHelper.absolute_secret_store_path(relative_path)
      end

      def self.description
        "Copy files specified in `.config` from the secrets repository to the project. Specify force:true to avoid confirmation"
      end

      def self.authors
        ["Jeremy Massel"]
      end

      def self.details
        "Copy files specified in `.config` from the secrets repository to the project. Specify force:true to avoid confirmation"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :force,
                             env_name: "FORCE_OVERWRITE",
                             description: "Overwrite copied files without confirmation",
                             optional: true,
                             default_value: false,
                             is_string: false),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
