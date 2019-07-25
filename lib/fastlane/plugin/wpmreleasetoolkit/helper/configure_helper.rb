require 'fastlane_core/ui/ui'
require 'fileutils'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class ConfigureHelper

      ### Returns the contents of the project's `.configure` file.
      ### If the file doesn't exist, it'll return an empty sample hash
      ### that can later be saved to `.configure`.
      def self.configuration

        if self.configuration_path_exists
          file = File.read(FilesystemHelper::configure_file)
          return data_hash = JSON.parse(file)
        else
          configuration = Hash.new
          configuration["branch"] = ""
          configuration["pinned_hash"] = ""
          configuration["files_to_copy"] = []
          configuration["file_dependencies"] = []

          return configuration
        end
      end

      ### Returns whether or not the `.configure` file exists in the project.
      def self.configuration_path_exists
        File.file?(FilesystemHelper::configure_file)
      end

      ### A global helper to save the current configure hash to `.configure`.
      def self.update_configuration(hash)

        if hash["files_to_copy"] == nil
            hash["files_to_copy"] = []
        end

        if hash["file_dependencies"] == nil
            hash["file_dependencies"] = []
        end

        File.open(FilesystemHelper::configure_file, 'w') { |file|
            file.write(JSON.pretty_generate(hash))
        }
      end

      ###
      #       CONFIGURE FILE METHODS
      ###

      ### Reads current branch name and commit hash `~/.mobile-secrets` and writes them
      ### to the project's `.configure` file.
      def self.update_configure_file_from_repository
        update_configure_file_branch_name(repo_branch_name)
        update_configure_file_commit_hash(repo_commit_hash)
      end

      ### Returns the `branch` field of the project's `.configure` file.
      def self.configure_file_branch_name
        configuration["branch"]
      end

      ### Writes the provided new branch name to the `branch` field of the project's `.configure` file.
      def self.update_configure_file_branch_name(new_branch_name)
        new_configuration = configuration
        new_configuration["branch"] = new_branch_name
        update_configuration(new_configuration)
      end

      ### Returns the `pinned_hash` field of the project's `.configure` file.
      def self.configure_file_commit_hash
        configuration["pinned_hash"].to_s
      end

      ### Writes the provided new commit hash to the `pinned_hash` field of the project's `.configure` file.
      def self.update_configure_file_commit_hash(new_hash)
        new_configuration = configuration
        new_configuration["pinned_hash"] = new_hash
        update_configuration(new_configuration)
      end

      ###
      #       SECRETS REPO METHODS
      ###

      ### Returns the currently checked out branch for the `~/.mobile-secrets` repository.
      ### NB: Returns nil if the repo is in a detached HEAD state.
      def self.repo_branch_name
        result = `cd #{repository_path} && git rev-parse --abbrev-ref HEAD`.strip
        (result == "HEAD") ? nil : result
      end

      ### Returns the most recent commit hash in the `~/.mobile-secrets` repository.
      def self.repo_commit_hash
        hash = `cd #{repository_path} && git rev-parse --verify HEAD`
        hash.strip
      end

      ### Returns an absolute path to the `~/.mobile-secrets` repository.
      def self.repository_path
        FilesystemHelper.secret_store_dir
      end

      ### Returns whether the ~/.mobile-secrets` repository is clean or dirty.
      def self.repo_has_changes
        result = `cd #{repository_path} && git status --porcelain`
        result.empty?
      end

      ### Returns whether or not the `.configure` file has a pinned hash that's older than the most recent
      ### ~/.mobile-secrets` commit hash.
      def self.configure_file_is_behind_local
      	configure_file_commits_behind_repo > 0
      end

      def self.configure_file_commits_behind_repo
     	# Get a sily number of revisions to ensure we don't miss any
      	result = `cd #{repository_path} && git --no-pager log -10000 --pretty=format:"%H" && echo`
      	hashes = result.each_line.map{ |s| s.strip }.reverse

      	index_of_configure_hash = hashes.find_index(configure_file_commit_hash)
      	index_of_repo_commit_hash = hashes.find_index(repo_commit_hash)

      	if index_of_configure_hash >= index_of_repo_commit_hash
      		return 0
      	end

      	index_of_repo_commit_hash - index_of_configure_hash
      end

      ### Get a list of files changed in the secrets repo between to commits
      def self.files_changed_between(commit_hash_1, commit_hash_2)
        result = `cd #{repository_path} && git diff --name-only #{commit_hash_1}...#{commit_hash_2}`
        result.each_line.map{ |s| s.strip }
      end

      ### Determine whether ~/.mobile-secrets` repository is behind its remote counterpart.
      ### (ie – the remote repo has changes that the local repo doesn't)
      def self.repo_is_behind_remote
        repo_commits_behind_remote > 0
      end

      ### Determine how far behind the remote repo the ~/.mobile-secrets` repository is.
      def self.repo_commits_behind_remote
        matches = repo_status.match(/behind \d+/)

        if matches == nil
            return 0
        end

        parse_distance(matches[0])
      end

      ### Determine whether ~/.mobile-secrets` repository is ahead of its remote counterpart.
      ### (ie – the local repo has changes that the remote repo doesn't)
      def self.repo_is_ahead_of_remote
        repo_commits_ahead_of_remote > 0
      end

      ### Determine how far ahead of the remote repo the ~/.mobile-secrets` repository is.
      def self.repo_commits_ahead_of_remote
        matches = repo_status.match(/ahead \d+/)

        if matches == nil
            return 0
        end

        parse_distance(matches[0])
      end

      ### A helper function to extract the distance from the provided string.
      ### (ie – this function will recieve "behind 2" or "ahead 6" and return 2 or 6, respectively.
      def self.parse_distance(match)
        distance = match.to_s.scan(/\d+/).first

        if distance == nil
            return 0
        end

        distance.to_i
      end

      ### A helper function to determine how far apart the local and remote repos are.
      def self.repo_status
        `cd #{repository_path} && git fetch && git status --porcelain -b`
      end

      ###
      #       FILES
      ###

      ### Returns whether or not the `files_to_copy` hash in `.configure` is empty.
      def self.has_files
        !files_to_copy.empty?
      end

      ### Returns the list of files to copy from `.configure`.
      def self.files_to_copy
        self.configuration["files_to_copy"]
      end

      ### Returns the list of files that this project uses from `.configure`.
      def self.file_dependencies
        file_dependencies = self.configuration["file_dependencies"]
        file_dependencies ||= []

        # Allows support for specifying directories – they'll be expanded recursively
        expanded_file_dependencies = file_dependencies.map { |path|

            abs_path = self.mobile_secrets_path(path)

            if File.directory?(abs_path)
                Dir.glob("#{abs_path}**/*").map{ |path|
                    path.gsub(repository_path + "/", "")
                }
            else
                return path
            end
        }

        self.files_to_copy.map { |o| o["file"] } + expanded_file_dependencies
      end

      ## If we specify a directory in `file_dependencies` instead of listing each file
      ## individually, there may be new files that we don't know about. This method finds those.
      def self.new_files_in(files)
        file_dependencies = self.configuration["file_dependencies"]
        file_dependencies ||= []

        directory_dependencies = file_dependencies.select { |path|
            File.directory?(self.mobile_secrets_path(path))
        }

        new_files = []

        files.each do |path|
            directory_dependencies.each do |directory_name|
                if path.start_with?(directory_name)
                    new_files << path
                end
            end
        end

        new_files
      end

      # Adds a file to the `.configure` file's `files_to_copy` hash.
      # The hash for this method must contain the `source` and `destination` keys
      def self.add_file(params)

        unless(params[:source])
            UI.user_error!("You must pass a `source` to `add_file`")
        end

        unless(params[:destination])
            UI.user_error!("You must pass a `destination` to `add_file`")
        end

        new_file = {
            file: params[:source],
            destination: params[:destination],
        }

        data_hash = self.configuration
        data_hash["files_to_copy"].push(new_file)
        update_configuration(data_hash)
      end

      ## Turns a relative mobile secrets path into an absolute path
      def self.mobile_secrets_path(path)
        "#{repository_path}/#{path}"
      end
    end
  end
end
