require 'fastlane_core/ui/ui'
require 'octokit'
require 'open-uri'
require 'securerandom'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class GithubHelper
      attr_reader :client

      # Helper for GitHub Actions
      #
      # @param [String?] github_token GitHub OAuth access token
      #
      def initialize(github_token:)
        @client = Octokit::Client.new(access_token: github_token)

        # Fetch the current user
        user = @client.user
        UI.message("Logged in as: #{user.name}")

        # Auto-paginate to ensure we're not missing data
        @client.auto_paginate = true
      end

      def get_milestone(repository, release)
        miles = client.list_milestones(repository)
        mile = nil

        miles&.each do |mm|
          mile = mm if mm[:title].start_with?(release)
        end

        return mile
      end

      # Fetch all the PRs for a given milestone
      #
      # @param [String] repository The repository name, including the organization (e.g. `wordpress-mobile/wordpress-ios`)
      # @param [String] milestone The name of the milestone we want to fetch the list of PRs for (e.g.: `16.9`)
      # @return [<Sawyer::Resource>] A list of the PRs for the given milestone, sorted by number
      #
      def get_prs_for_milestone(repository, milestone)
        client.search_issues(%(type:pr milestone:"#{milestone}" repo:#{repository}))[:items].sort_by(&:number)
      end

      def get_last_milestone(repository)
        options = {}
        options[:state] = 'open'

        milestones = client.list_milestones(repository, options)
        return nil if milestones.nil?

        last_stone = nil
        milestones.each do |mile|
          mile_vcomps = mile[:title].split[0].split('.')
          if last_stone.nil?
            last_stone = mile unless mile_vcomps.length < 2
          else
            begin
              last_vcomps = last_stone[:title].split[0].split('.')
              last_stone = mile if Integer(mile_vcomps[0]) > Integer(last_vcomps[0]) || Integer(mile_vcomps[1]) > Integer(last_vcomps[1])
            rescue StandardError
              puts 'Found invalid milestone'
            end
          end
        end

        last_stone
      end

      # Creates a new milestone
      #
      # @param [String] repository The repository name, including the organization (e.g. `wordpress-mobile/wordpress-ios`)
      # @param [String] title The name of the milestone we want to create (e.g.: `16.9`)
      # @param [Time] due_date Milestone due date—which will also correspond to the code freeze date
      # @param [Integer] days_until_submission Number of days from code freeze to submission to the App Store / Play Store
      # @param [Integer] days_until_release Number of days from code freeze to release
      #
      def create_milestone(repository:, title:, due_date:, days_until_submission:, days_until_release:)
        UI.user_error!('days_until_release must be greater than zero.') unless days_until_release.positive?
        UI.user_error!('days_until_submission must be greater than zero.') unless days_until_submission.positive?
        UI.user_error!('days_until_release must be greater or equal to days_until_submission.') unless days_until_release >= days_until_submission

        submission_date = due_date.to_datetime.next_day(days_until_submission)
        release_date = due_date.to_datetime.next_day(days_until_release)
        comment = <<~MILESTONE_DESCRIPTION
          Code freeze: #{due_date.to_datetime.strftime('%B %d, %Y')}
          App Store submission: #{submission_date.strftime('%B %d, %Y')}
          Release: #{release_date.strftime('%B %d, %Y')}
        MILESTONE_DESCRIPTION

        options = {}
        # == Workaround for GitHub API bug ==
        #
        # It seems that whatever date we send to the API, GitHub will 'floor' it to the date that seems to be at
        # 00:00 PST/PDT and then discard the time component of the date we sent.
        # This means that, when we cross the November DST change date, where the due date of the previous milestone
        # was e.g. `2022-10-31T07:00:00Z` and `.next_day(14)` returns `2022-11-14T07:00:00Z` and we send that value
        # for the `due_on` field via the API, GitHub ends up creating a milestone with a due of `2022-11-13T08:00:00Z`
        # instead, introducing an off-by-one error on that due date.
        #
        # This is a bug in the GitHub API, not in our date computation logic.
        # To solve this, we trick it by forcing the time component of the ISO date we send to be `12:00:00Z`.
        options[:due_on] = due_date.strftime('%Y-%m-%dT12:00:00Z')
        options[:description] = comment
        client.create_milestone(repository, title, options)
      end

      # Creates a Release on GitHub as a Draft
      #
      # @param [String] repository The repository to create the GitHub release on. Typically a repo slug (<org>/<repo>).
      # @param [String] version The version for which to create this release. Will be used both as the name of the tag and the name of the release.
      # @param [String?] target The commit SHA or branch name that this release will point to when it's published and creates the tag.
      #        If nil (the default), will use the repo's current HEAD commit at the time this method is called.
      #        Unused if the tag already exists.
      # @param [String] description The text to use as the release's body / description (typically the release notes)
      # @param [Array<String>] assets List of file paths to attach as assets to the release
      # @param [TrueClass|FalseClass] prerelease Indicates if this should be created as a pre-release (i.e. for alpha/beta)
      # @param [TrueClass|FalseClass] is_draft Indicates if this should be created as a draft release
      #
      def create_release(repository:, version:, description:, assets:, prerelease:, is_draft:, target: nil)
        release = client.create_release(
          repository,
          version, # tag name
          name: version, # release name
          target_commitish: target || Git.open(Dir.pwd).log.first.sha,
          prerelease: prerelease,
          draft: is_draft,
          body: description
        )
        assets.each do |file_path|
          client.upload_asset(release[:url], file_path, content_type: 'application/octet-stream')
        end
      end

      # Downloads a file from the given GitHub tag
      #
      # @param [String] repository The repository name (including the organization)
      # @param [String] tag The name of the tag we're downloading from
      # @param [String] file_path The path, inside the project folder, of the file to download
      # @param [String] download_folder The folder which the file should be downloaded into
      # @return [String] The path of the downloaded file, or nil if something went wrong
      #
      def download_file_from_tag(repository:, tag:, file_path:, download_folder:)
        repository = repository.delete_prefix('/').chomp('/')
        file_path = file_path.delete_prefix('/').chomp('/')
        file_name = File.basename(file_path)
        download_path = File.join(download_folder, file_name)

        download_url = client.contents(repository, path: file_path, ref: tag).download_url

        begin
          uri = URI.parse(download_url)
          uri.open do |remote_file|
            File.write(download_path, remote_file.read)
          end
        rescue OpenURI::HTTPError
          return nil
        end

        download_path
      end

      # Creates (or updates an existing) GitHub PR Comment
      def comment_on_pr(project_slug:, pr_number:, body:, reuse_identifier: SecureRandom.uuid)
        comments = client.issue_comments(project_slug, pr_number)

        reuse_marker = "<!-- REUSE_ID: #{reuse_identifier} -->"

        existing_comment = comments.find do |comment|
          # Only match comments posted by the owner of the GitHub Token, and with the given reuse ID
          comment.user.id == client.user.id and comment.body.include?(reuse_marker)
        end

        comment_body = reuse_marker + body

        if existing_comment.nil?
          client.add_comment(project_slug, pr_number, comment_body)
        else
          client.update_comment(project_slug, existing_comment.id, comment_body)
        end

        reuse_identifier
      end

      # Update a milestone for a repository
      #
      # @param [String] repository The repository name (including the organization)
      # @param [String] number The number of the milestone we want to fetch
      # @param options [Hash] A customizable set of options.
      # @option options [String] :title A unique title.
      # @option options [String] :state
      # @option options [String] :description A meaningful description
      # @option options [Time] :due_on Set if the milestone has a due date
      # @return [Milestone] A single milestone object
      # @see http://developer.github.com/v3/issues/milestones/#update-a-milestone
      #
      def update_milestone(repository:, number:, **options)
        client.update_milestone(repository, number, options)
      end

      # Remove the protection of a single branch from a repository
      #
      # @param [String] repository The repository name (including the organization)
      # @param [String] branch The branch name
      # @param [Hash] options A customizable set of options.
      # @see https://docs.github.com/en/rest/branches/branch-protection#update-branch-protection
      #
      def remove_branch_protection(repository:, branch:, **options)
        client.unprotect_branch(repository, branch, options)
      end

      # Protects a single branch from a repository
      #
      # @param [String] repository The repository name (including the organization)
      # @param [String] branch The branch name
      # @param options [Hash] A customizable set of options.
      # @see https://docs.github.com/en/rest/branches/branch-protection#update-branch-protection
      #
      def set_branch_protection(repository:, branch:, **options)
        client.protect_branch(repository, branch, options)
      end

      # Creates a GithubToken Fastlane ConfigItem
      #
      # @return [FastlaneCore::ConfigItem] The Fastlane ConfigItem for GitHub OAuth access token
      #
      def self.github_token_config_item
        FastlaneCore::ConfigItem.new(
          key: :github_token,
          env_name: 'GITHUB_TOKEN',
          description: 'The GitHub OAuth access token',
          optional: false,
          type: String
        )
      end
    end
  end
end
