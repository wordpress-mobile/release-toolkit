require 'fastlane_core/ui/ui'
require 'octokit'
require 'open-uri'
require 'securerandom'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class GithubHelper
      def self.github_token
        token = [
          'GHHELPER_ACCESS', # For historical reasons / backward compatibility
          'GITHUB_TOKEN',    # Used by the `gh` CLI tool
        ].map { |key| ENV[key] }
                .compact
                .first

        token || UI.user_error!('Please provide a GitHub authentication token via the `GITHUB_TOKEN` environment variable')
      end

      def self.github_client
        client = Octokit::Client.new(access_token: github_token)

        # Fetch the current user
        user = client.user
        UI.message("Logged in as: #{user.name}")

        # Auto-paginate to ensure we're not missing data
        client.auto_paginate = true

        client
      end

      def self.get_milestone(repository, release)
        miles = github_client().list_milestones(repository)
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
        github_client.search_issues(%(type:pr milestone:"#{milestone}" repo:#{repository}))[:items].sort_by(&:number)
      end

      def self.get_last_milestone(repository)
        options = {}
        options[:state] = 'open'

        milestones = github_client().list_milestones(repository, options)
        return nil if milestones.nil?

        last_stone = nil
        milestones.each do |mile|
          mile_vcomps = mile[:title].split[0].split('.')
          if last_stone.nil?
            last_stone = mile unless mile_vcomps.length < 2
          else
            begin
              last_vcomps = last_stone[:title].split[0].split('.')
              last_stone = mile if mile_vcomps[0] > last_vcomps[0] || mile_vcomps[1] > last_vcomps[1]
            rescue StandardError
              puts 'Found invalid milestone'
            end
          end
        end

        last_stone
      end

      def self.create_milestone(repository, newmilestone_number, newmilestone_duedate, need_submission)
        submission_date = need_submission ? newmilestone_duedate.to_datetime.next_day(11) : newmilestone_duedate.to_datetime.next_day(14)
        release_date = newmilestone_duedate.to_datetime.next_day(14)
        comment = "Code freeze: #{newmilestone_duedate.to_datetime.strftime('%B %d, %Y')} App Store submission: #{submission_date.strftime('%B %d, %Y')} Release: #{release_date.strftime('%B %d, %Y')}"

        options = {}
        options[:due_on] = newmilestone_duedate
        options[:description] = comment
        github_client().create_milestone(repository, newmilestone_number, options)
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
        release = github_client().create_release(
          repository,
          version, # tag name
          name: version, # release name
          target_commitish: target || Git.open(Dir.pwd).log.first.sha,
          draft: true,
          prerelease: prerelease,
          body: description
        )
        assets.each do |file_path|
          github_client().upload_asset(release[:url], file_path, content_type: 'application/octet-stream')
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

        begin
          uri = URI.parse("https://raw.githubusercontent.com/#{repository}/#{tag}/#{file_path}")
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
        client = github_client
        comments = client.issue_comments(project_slug, pr_number)

        complete_reuse_identifier = "<!-- REUSE_ID: #{reuse_identifier} -->"

        existing_comment = comments
                           .select { |comment| comment.user.id == client.user.id } # Only match comments posted by the owner of the GitHub Token
                           .find { |comment| comment.body.include?(complete_reuse_identifier) }

        comment_body = complete_reuse_identifier + body

        if existing_comment.nil?
          client.add_comment(project_slug, pr_number, comment_body)
        else
          client.update_comment(project_slug, existing_comment.id, comment_body)
        end

        reuse_identifier
      end
    end
  end
end
