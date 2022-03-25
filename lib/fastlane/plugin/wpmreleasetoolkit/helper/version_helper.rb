module Fastlane
  module Helper
    class VersionHelper
      def initialize(git: nil)
        @git = git || Git.open(Dir.pwd)
      end

      # Generate a prototype build name based on the current pr_number and commit.
      #
      # Takes optional `pr_number:` and `commit:` arguments to generate a build name
      # based on a different pr_number and commit.
      def prototype_build_name(pr_number: nil, commit: nil)
        pr_number ||= current_pr_number
        commit ||= current_commit

        UI.user_error!('Unable to find a PR in the environment – falling back to a branch-based version name. To run this in a development environment, try: `export LOCAL_PR_NUMBER=1234`') if pr_number.nil?

        "pr-#{pr_number}-#{commit.sha[0, 7]}"
      end

      # Generate a prototype build number based on the most recent commit.
      #
      # Takes an optional `commit:` argument to generate a build number based
      # on a different commit.
      def prototype_build_number(commit: nil)
        commit ||= current_commit
        commit.date.to_i
      end

      # Generate an alpha build name based on the current branch and commit.
      #
      # Takes optional `branch:` and `commit:` arguments to generate a build name
      # based on a different branch and commit.
      def alpha_build_name(branch: nil, commit: nil)
        branch ||= current_branch
        commit ||= current_commit

        "#{branch}-#{commit.sha[0, 7]}"
      end

      # Generate an alpha number.
      #
      # Allows injecting a specific `DateTime` to derive the build number from
      def alpha_build_number(now: DateTime.now)
        now.to_i
      end

      # Find the newest rc of a specific version in a given GitHub repository.
      def newest_rc_for_version(version, repository:, github_client:)
        tags = github_client.tags(repository)

        # GitHub Enterprise can return raw HTML if the connection isn't
        # working, so we need to validate that this is what we expect it is
        UI.crash! 'Unable to connect to GitHub. Please try again later.' unless tags.is_a? Array

        tags.map { |t| Version.create(t[:name]) }
            .compact
            .filter { |v| v.is_rc_of(version) }
            .sort
            .reverse
            .first
      end

      # Given the current version of an app and its Git Repository,
      # use the existing tags to figure out which RC version should be
      # the next one.
      def next_rc_for_version(version, repository:, github_client:)
        most_recent_rc_version = newest_rc_for_version(version, repository: repository, github_client: github_client)

        # If there is no RC tag, this must be the first one ever
        return version.next_rc_version if most_recent_rc_version.nil?

        # If we have a previous RC for this version, we can just bump it
        most_recent_rc_version.next_rc_version
      end

      private

      # Get the most recent commit on the current branch of the Git repository
      def current_commit
        @git.log.first
      end

      # Get the current branch of the Git repository
      def current_branch
        @git.current_branch
      end

      # Get the current PR number from the CI environment
      def current_pr_number
        %w[
          BUILDKITE_PULL_REQUEST
          CIRCLE_PR_NUMBER
          LOCAL_PR_NUMBER
        ].map { |k| ENV[k] }
          .compact
          .first
      end
    end
  end
end
