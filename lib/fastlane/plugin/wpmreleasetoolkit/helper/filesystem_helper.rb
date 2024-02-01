require 'fastlane_core/ui/ui'
require 'fileutils'
require 'digest'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class FilesystemHelper
      ### Traverse the file system to find the root project directory.
      ### For the purposes of this function, we're assuming the root project
      ### directory is the one with the `.git` file in it.
      def self.project_path
        continue = true
        dir = Pathname.new(Dir.pwd)

        while continue
          child_filenames = dir.children.map! { |x| File.basename(x) }

          if child_filenames.include? '.git'
            continue = false
          else
            dir = dir.parent
          end

          UI.user_error!("Unable to determine the project root directory – #{Dir.pwd} doesn't appear to reside within a git repository.") if dir.root?
        end

        dir
      end

      def self.plugin_root
        continue = true
        dir = Pathname.new(__FILE__).dirname

        while continue
          child_filenames = dir.children.map! { |x| File.basename(x) }

          # The first case is for development – where the `.gemspec` is present in the project root
          # The second case is for production – where there's no `.gemspec`, but the root dir of the plugin is named `fastlane-plugin-wpmreleasetoolkit-{version}`.
          if child_filenames.include?('fastlane-plugin-wpmreleasetoolkit.gemspec') || File.basename(dir).start_with?('fastlane-plugin-wpmreleasetoolkit-')
            continue = false
          else
            dir = dir.parent
          end

          UI.user_error!('Unable to determine the plugin root directory.') if dir.root?
        end

        dir
      end

      ### Returns the path to the project's `.configure` file.
      def self.configure_file
        Pathname.new(project_path) + '.configure'
      end

      ### Returns the path to the project's `.configure-files` directory.
      def self.configure_files_dir
        Pathname.new(project_path) + '.configure-files'
      end

      def self.encrypted_file_path(file)
        File.join(configure_files_dir, "#{File.basename(file)}.enc")
      end

      ### Returns the path to the `~/.mobile-secrets` directory.
      def self.secret_store_dir
        "#{Dir.home}/.mobile-secrets"
      end

      ### Transforms a relative path within the secret store to an absolute path on disk.
      def self.absolute_secret_store_path(relative_path)
        File.join(secret_store_dir, relative_path)
      end

      ### Path to keys.json in the secrets repository
      def self.secret_store_keys_path
        File.join(secret_store_dir, 'keys.json')
      end

      ### Transforms a relative path within the project to an absolute path on disk.
      def self.absolute_project_path(relative_path)
        File.join(project_path, relative_path)
      end

      ### Returns the `sha1` hash of a file, given the absolute path.
      def self.file_hash(absolute_path)
        UI.user_error!("Unable to hash #{absolute_path} – the file does not exist") unless File.file?(absolute_path)

        Digest::SHA1.file absolute_path
      end
    end
  end
end
