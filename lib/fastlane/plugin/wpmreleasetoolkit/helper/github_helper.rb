require 'fastlane_core/ui/ui'
require 'octokit'
require 'open-uri'
require 'securerandom'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class GithubHelper
      # Helper for GitHub Actions
      #
      # @param [String?] githubtoken GitHub OAuth access token
      #
      def initialize(github_token:)
        @client = Octokit::Client.new(access_token: github_token)

        # Fetch the current user
        user = @client.user
        UI.message("Logged in as: #{user.name}")

        # Auto-paginate to ensure we're not missing data
        @client.auto_paginate = true
      end

      def self.get_milestone(repository, release)
        miles = @client.list_milestones(repository)
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
      def self.get_prs_for_milestone(repository, milestone)
        @client.search_issues(%(type:pr milestone:"#{milestone}" repo:#{repository}))[:items].sort_by(&:number)
      end

      def self.get_last_milestone(repository)
        options = {}
        options[:state] = 'open'

        milestones = @client.list_milestones(repository, options)
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

      def self.create_milestone(repository, newmilestone_number, newmilestone_duedate, newmilestone_duration, number_of_days_from_code_freeze_to_release, need_submission)
        # If there is a review process, we want to submit the binary 3 days before its release
        #
        # Using 3 days is mostly for historical reasons where we release the apps on Monday and submit them on Friday.
        days_until_submission = need_submission ? (number_of_days_from_code_freeze_to_release - 3) : newmilestone_duration
        submission_date = newmilestone_duedate.to_datetime.next_day(days_until_submission)
        release_date = newmilestone_duedate.to_datetime.next_day(number_of_days_from_code_freeze_to_release)
        comment = "Code freeze: #{newmilestone_duedate.to_datetime.strftime('%B %d, %Y')} App Store submission: #{submission_date.strftime('%B %d, %Y')} Release: #{release_date.strftime('%B %d, %Y')}"

        options = {}
        options[:due_on] = newmilestone_duedate
        options[:description] = comment
        @client.create_milestone(repository, newmilestone_number, options)
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
      #
      def self.create_release(repository:, version:, target: nil, description:, assets:, prerelease:)
        release = @client.create_release(
          repository,
          version, # tag name
          name: version, # release name
          target_commitish: target || Git.open(Dir.pwd).log.first.sha,
          draft: true,
          prerelease: prerelease,
          body: description
        )
        assets.each do |file_path|
          @client.upload_asset(release[:url], file_path, content_type: 'application/octet-stream')
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
      def self.download_file_from_tag(repository:, tag:, file_path:, download_folder:)
        repository = repository.delete_prefix('/').chomp('/')
        file_path = file_path.delete_prefix('/').chomp('/')
        file_name = File.basename(file_path)
        download_path = File.join(download_folder, file_name)

        download_url = @client.contents(repository, path: file_path, ref: tag).download_url

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
      def self.comment_on_pr(project_slug:, pr_number:, body:, reuse_identifier: SecureRandom.uuid)
        comments = @client.issue_comments(project_slug, pr_number)

        reuse_marker = "<!-- REUSE_ID: #{reuse_identifier} -->"

        existing_comment = comments.find do |comment|
          # Only match comments posted by the owner of the GitHub Token, and with the given reuse ID
          comment.user.id == @client.user.id and comment.body.include?(reuse_marker)
        end

        comment_body = reuse_marker + body

        if existing_comment.nil?
          @client.add_comment(project_slug, pr_number, comment_body)
        else
          @client.update_comment(project_slug, existing_comment.id, comment_body)
        end

        reuse_identifier
      end
    end
  end
end
