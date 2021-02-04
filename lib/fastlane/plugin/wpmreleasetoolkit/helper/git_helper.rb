require 'git'

module Fastlane
  module Helper
    module GitHelper

      def self.is_git_repo
        system "git rev-parse --git-dir 1> /dev/null 2>/dev/null"
      end

      def self.has_git_lfs
        return false unless is_git_repo
        `git config --get-regex lfs`.length > 0
      end

      # Switch to the given branch and pull its latest commits.
      #
      # @param [String,Hash] branch Name of the branch to pull.
      #        If you provide a Hash with a single key=>value pair, it will build the branch name as `"#{key}/#{value}"`,
      #        i.e. `checkout_and_pull(release: version)` is equivalent to `checkout_and_pull("release/#{version}")`.    
      #
      # @return [Bool] True if it succeeded switching and pulling, false if there was an error during the switch or pull.
      #
      def self.checkout_and_pull(branch)
        branch = branch.first.join('/') if branch.is_a?(Hash)
        Action.sh("git", "checkout", branch)
        Action.sh("git", "pull")
        return true
      rescue
        return false
      end

      # Create a new branch named `branch_name`, cutting it from branch/commit/tag `from`, and push it
      #
      # If the branch with that name already exists, it will instead switch to it and pull new commits.
      #
      # @param [String] branch_name The full name of the new branch to create, e.g "release/1.2"
      # @param [String?] from The branch or tag from which to cut the branch from.
      #        If `nil`, will cut the new branch from the current commit. Otherwise, will checkout that commit/branch/tag before cutting the branch.
      # @param [Bool] push If true, will also push the branch to `origin`, tracking the upstream branch with the local one.
      #
      def self.create_branch(branch_name, from: nil, push: true)
        if branch_exists?(branch_name)
          UI.message("Branch #{branch_name} already exists. Skipping creation.")
          Action.sh("git", "checkout", branch_name)
          Action.sh("git", "pull", "origin", branch_name)
        else
          Action.sh("git", "checkout", from) unless from.nil?
          Action.sh("git", "checkout", "-b", branch_name)
          Action.sh("git", "push", "-u", "origin", branch_name) if push
        end
      end

      # `git add` the specified files (if any provided) then commit them using the provided message.
      # Optionally, push the commit to the remote too.
      #
      # @param [String] message The commit message to use
      # @param [String|Array<String>] files A file or array of files to git-add before creating the commit.
      #        use `nil` or `[]` if you already added the files in a separate step and don't wan't this method to add any new file before commit.
      #        Also accepts the special symbol `:all` to add all the files (`git commit -a -m …`).
      # @param [Bool] push If true, will `git push` to `origin` after the commit has been created. Defaults to `false`.
      #
      def self.commit(message:, files: nil, push: false)
        files = [files] if files.is_a?(String)
        args = []
        if files  == :all
          args = ['-a']
        elsif !files.nil? && !files.empty?
          Action.sh("git", "add", *files)
        end
        Action.sh("git", "commit", *args, "-m", message)
        Action.sh("git", "push", "origin", "HEAD") if push
      end

      # Creates a tag for the given version, and optionally push it to the remote.
      #
      # @param [String] version The name of the tag to push, e.g. "1.2"
      # @param [Bool] push If true 9the default), the tag will also be pushed to `origin`
      #
      def self.create_tag(version, push: true)
        Action.sh("git", "tag", version)
        Action.sh("git", "push", "origin", version) if push
      end

      # Returns the list of tags that are pointing to the current commit (HEAD)
      #
      # @return [Array<String>] List of tags associated with the HEAD commit
      #
      def self.list_tags_on_current_commit
        Action.sh("git", "tag", "--points-at", "HEAD").split("\n")
      end

      # Checks if a branch exists locally.
      #
      # @param [String] branch_name The name of the branch to check for
      #
      # @return [Bool] True if the branch exists in the local working copy, false otherwise.
      #
      def self.branch_exists?(branch_name)
        !Action.sh("git", "branch", "--list", branch_name).empty?
      end

      # Ensure that we are on the expected branch, and abort if not.
      #
      # @param [String] branch_name The name of the branch we expect to be on
      #
      # @raise [UserError] Raises a user_error! and interrupts the lane if we are not on the expected branch.
      #
      def self.ensure_on_branch!(branch_name)
        current_branch_name = Action.sh("git", "symbolic-ref", "-q", "HEAD")
        UI.user_error!("This command works only on #{branch_name} branch") unless current_branch_name.include?(branch_name)
      end
    end
  end
end
