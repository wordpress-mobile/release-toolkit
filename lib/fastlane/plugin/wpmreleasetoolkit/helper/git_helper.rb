require 'git'

module Fastlane
  module Helper
    # Helper methods to execute git-related operations
    #
    module GitHelper
      # Fallback default branch of the client repository.
      DEFAULT_GIT_BRANCH = 'trunk'.freeze

      # Checks if the given path, or current directory if no path is given, is inside a Git repository
      #
      # @param [String] path An optional path where to check if a Git repo exists.
      #
      # @return [Bool] True if the current directory is the root of a git repo (i.e. a local working copy) or a subdirectory of one.
      #
      def self.is_git_repo?(path: Dir.pwd)
        # If the path doesn't exist, find its first ancestor.
        path = first_existing_ancestor_of(path: path)
        # Get the path's directory, so we can look in it for the Git folder
        dir = path.directory? ? path : path.dirname

        # Recursively look for the Git folder until it's found or we read the the file system root
        dir = dir.parent until Dir.entries(dir).include?('.git') || dir.root?

        # If we reached the root, we haven't found a repo.
        # (Technically, there could be a repo in the root of the system, but that's a usecase that we don't need to support at this time)
        dir.root? == false
      end

      # Travels back the hierarchy of the given path until it finds an existing ancestor, or it reaches the root of the file system.
      #
      # @param [String] path The path to inspect
      #
      # @return [Pathname] The first existing ancestor, or `path` itself if it exists
      #
      def self.first_existing_ancestor_of(path:)
        p = Pathname(path).expand_path
        p = p.parent until p.exist? || p.root?
        p
      end

      # Check if the current directory has git-lfs enabled
      #
      # @return [Bool] True if the current directory is a git working copy and has git-lfs enabled.
      #
      def self.has_git_lfs?
        return false unless is_git_repo?

        !`git config --get-regex lfs`.empty?
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
        Action.sh('git', 'checkout', branch)
        Action.sh('git', 'pull')
        true
      rescue StandardError
        false
      end

      # Update every submodule in the current git repository
      #
      # @deprecated This method is going to be removed soon. Fastlane has a built-in `git_submodule_update` action that can be used instead.
      #
      def self.update_submodules
        UI.deprecated("The `update_submodules` method will soon be removed from `release-toolkit`. Please use fastlane's `git_submodule_update` action instead.")
        Action.sh('git', 'submodule', 'update', '--init', '--recursive')
      end

      # Create a new branch named `branch_name`, cutting it from branch/commit/tag `from`
      #
      # If the branch with that name already exists, it will instead switch to it and pull new commits.
      #
      # @param [String] branch_name The full name of the new branch to create, e.g "release/1.2"
      # @param [String?] from The branch or tag from which to cut the branch from.
      #        If `nil`, will cut the new branch from the current commit. Otherwise, will checkout that commit/branch/tag before cutting the branch.
      #
      def self.create_branch(branch_name, from: nil)
        if branch_exists?(branch_name)
          UI.message("Branch #{branch_name} already exists. Skipping creation.")
          Action.sh('git', 'checkout', branch_name)
          Action.sh('git', 'pull', 'origin', branch_name)
        else
          Action.sh('git', 'checkout', from) unless from.nil?
          Action.sh('git', 'checkout', '-b', branch_name)
        end
      end

      # `git add` the specified files (if any provided) then commit them using the provided message.
      #
      # @param [String] message The commit message to use
      # @param [String|Array<String>] files A file or array of files to git-add before creating the commit.
      #        Use `nil` or `[]` if you already added the files in a separate step and don't wan't this method to add any new file before commit.
      #        Also accepts the special symbol `:all` to add all the files (`git commit -a -m …`).
      #
      # @return [Bool] True if commit was successful, false if there was an issue (most likely being "nothing to commit").
      #
      def self.commit(message:, files: nil)
        files = [files] if files.is_a?(String)
        args = []
        if files == :all
          args = ['-a']
        elsif !files.nil? && !files.empty?
          Action.sh('git', 'add', *files)
        end
        begin
          Action.sh('git', 'commit', *args, '-m', message)
          true
        rescue StandardError
          false
        end
      end

      # Get the SHA of a given git ref. Typically useful to get the SHA of the current HEAD commit.
      #
      # @param [String] ref The git ref (commit, branch name, 'HEAD', …) to resolve as a SHA
      # @return [String] The commit SHA of the ref
      #
      def self.get_commit_sha(ref: 'HEAD')
        Git.open(Dir.pwd).revparse(ref)
      end

      # Creates a tag for the given version, and optionally push it to the remote.
      #
      # @param [String] version The name of the tag to push, e.g. "1.2"
      # @param [Bool] push If true (the default), the tag will also be pushed to `origin`
      #
      def self.create_tag(version, push: true)
        Action.sh('git', 'tag', version)
        Action.sh('git', 'push', 'origin', version) if push
      end

      # Returns the list of tags that are pointing to the current commit (HEAD)
      #
      # @return [Array<String>] List of tags associated with the HEAD commit
      #
      def self.list_tags_on_current_commit
        Action.sh('git', 'tag', '--points-at', 'HEAD').split("\n")
      end

      # List all the tags in the local working copy, optionally filtering the list using a pattern
      #
      # @param [String] matching The pattern of the tag(s) to match and filter on; use "*" for wildcards.
      #        For example, `"1.2.*"` will match every tag starting with `"1.2."`. Defaults to '*' which lists all tags.
      #
      # @return [Array<String>] The list of local tags matching the pattern
      #
      def self.list_local_tags(matching: '*')
        Action.sh('git', 'tag', '--list', matching).split("\n")
      end

      # Delete the mentioned local tags in the local working copy, and optionally delete them on the remote too.
      #
      # @param [Array<String>] tags_to_delete The list of tags to delete
      # @param [Bool] delete_on_remote If true, will also delete the tag from the remote. Otherwise, it will only be deleted locally.
      #
      def self.delete_tags(tags_to_delete, delete_on_remote: false)
        g = Git.open(Dir.pwd)
        local_tag_names = g.tags.map(&:name)

        Array(tags_to_delete).each do |tag|
          g.delete_tag(tag) if local_tag_names.include?(tag)
          g.push('origin', ":refs/tags/#{tag}") if delete_on_remote
        end
      end

      # Fetch all the tags from the remote.
      #
      def self.fetch_all_tags
        Action.sh('git', 'fetch', '--tags')
      end

      # Returns the current git branch, or "HEAD" if it's not checked out to any branch
      # Can NOT be replaced using the environment variables such as `GIT_BRANCH` or `BUILDKITE_BRANCH`
      #
      # `fastlane` already has a helper action for this called `git_branch`, however it's modified
      # by CI environment variables. We need to check which branch we are actually on and not the
      # initial branch a CI build is started from, so we are using the `git_branch_name_using_HEAD`
      # helper instead.
      #
      # See https://docs.fastlane.tools/actions/git_branch/#git_branch
      #
      # @return [String] The current git branch, or "HEAD" if it's not checked out to any branch
      #
      def self.current_git_branch
        # We can't use `other_action.git_branch`, because it is modified by environment variables in Buildkite.
        Fastlane::Actions.git_branch_name_using_HEAD
      end

      # Checks if a branch exists locally.
      #
      # @param [String] branch_name The name of the branch to check for
      #
      # @return [Bool] True if the branch exists in the local working copy, false otherwise.
      #
      def self.branch_exists?(branch_name)
        !Action.sh('git', 'branch', '--list', branch_name).empty?
      end

      # Ensure that we are on the expected branch, and abort if not.
      #
      # @param [String] branch_name The name of the branch we expect to be on
      #
      # @raise [UserError] Raises a user_error! and interrupts the lane if we are not on the expected branch.
      #
      # @deprecated This method is going to be removed soon. Fastlane has a built-in `ensure_git_branch` action that can be used instead.
      #             After updating to Fastlane version `2.217.0` or later, the `FL_GIT_BRANCH_DONT_USE_ENV_VARS` environment
      #             variable can be set to `true` to disable the use of environment variables for the `git_branch` action that
      #             `ensure_git_branch` relies on. This will make `ensure_git_branch` work as expected in CI environments.
      #             See https://github.com/fastlane/fastlane/pull/21597 for more details.
      #
      def self.ensure_on_branch!(branch_name)
        UI.deprecated("The `ensure_on_branch!` method will soon be removed from `release-toolkit`. Please use fastlane's `ensure_git_branch` action (+ potentially set `FL_GIT_BRANCH_DONT_USE_ENV_VARS=true`) instead.")
        current_branch_name = Action.sh('git', 'symbolic-ref', '-q', 'HEAD')
        UI.user_error!("This command works only on #{branch_name} branch") unless current_branch_name.include?(branch_name)
      end

      # Checks whether a given path is ignored by Git, relying on Git's `check-ignore` under the hood.
      #
      # @param [String] path The path to check against `.gitignore`
      #
      # @return [Bool] True if the given path is ignored or outside a Git repository, false otherwise.
      def self.is_ignored?(path:)
        return true unless is_git_repo?(path: path)

        Actions.sh('git', 'check-ignore', path) do |status, _, _|
          status.success?
        end
      end
    end
  end
end
