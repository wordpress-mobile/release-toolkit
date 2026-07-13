# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Helper::GithubHelper do
  describe '#download_file_from_tag' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_tag) { '1.0' }
    let(:test_file) { 'test-folder/test-file.xml' }
    let(:content_url) { "https://api.github.com/repos/#{test_repo}/contents/#{test_file}?ref=#{test_tag}" }
    let(:client) do
      instance_double(
        Octokit::Client,
        contents: double(download_url: content_url), # rubocop:disable RSpec/VerifiedDoubles
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'fails if it does not find the right release on GitHub' do
      stub = stub_request(:get, content_url).to_return(status: [404, 'Not Found'])
      downloaded_file = download_file_from_tag(download_folder: './')
      expect(downloaded_file).to be_nil
      expect(stub).to have_been_made.once
    end

    it 'writes the raw content to a file' do
      stub = stub_request(:get, content_url).to_return(status: 200, body: 'my-test-content')
      Dir.mktmpdir('a8c-download-repo-file-') do |tmpdir|
        dst_file = File.join(tmpdir, 'test-file.xml')
        downloaded_file = download_file_from_tag(download_folder: tmpdir)
        expect(downloaded_file).to eq(dst_file)
        expect(stub).to have_been_made.once
        expect(File.read(dst_file)).to eq('my-test-content')
      end
    end

    def download_file_from_tag(download_folder:)
      helper = described_class.new(github_token: 'Fake-GitHubToken-123')
      helper.download_file_from_tag(repository: test_repo, tag: test_tag, file_path: test_file, download_folder: download_folder)
    end
  end

  describe '#find_pull_request' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:found_pr) { double('PullRequest', html_url: 'https://github.com/repo-test/project-test/pull/42') } # rubocop:disable RSpec/VerifiedDoubles
    let(:client) do
      instance_double(
        Octokit::Client,
        pull_requests: [found_pr],
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'qualifies an unqualified head with the repository owner and forwards the base' do
      expect(client).to receive(:pull_requests).with(test_repo, { state: 'open', head: 'repo-test:my-branch', base: 'trunk' })
      find_pull_request(head: 'my-branch', base: 'trunk')
    end

    it 'uses an already-qualified head as-is and omits the base when not provided' do
      expect(client).to receive(:pull_requests).with(test_repo, { state: 'open', head: 'someone:other-branch' })
      find_pull_request(head: 'someone:other-branch')
    end

    it 'returns the first matching pull request' do
      expect(find_pull_request(head: 'my-branch')).to eq(found_pr)
    end

    it 'returns nil when no pull request matches' do
      allow(client).to receive(:pull_requests).and_return([])
      expect(find_pull_request(head: 'my-branch')).to be_nil
    end

    def find_pull_request(head:, base: nil)
      described_class.new(github_token: 'Fake-GitHubToken-123').find_pull_request(repository: test_repo, head: head, base: base)
    end
  end

  describe '#get_last_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:last_stone) { mock_milestone('10.0') }
    let(:client) do
      instance_double(
        Octokit::Client,
        list_milestones: ['9.8 ❄️', '9.9'].map { |title| mock_milestone(title) }.append(last_stone),
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'returns correct milestone' do
      expect(client).to receive(:list_milestones)
      last_milestone = get_last_milestone(repository: test_repo)
      expect(last_milestone).to eq(last_stone)
    end

    def mock_milestone(title)
      { title: title }
    end

    def get_last_milestone(repository:)
      helper = described_class.new(github_token: 'Fake-GitHubToken-123')
      helper.get_last_milestone(repository: repository)
    end
  end

  describe '#comment_on_pr' do
    let(:client) do
      instance_double(
        Octokit::Client,
        issue_comments: [],
        add_comment: nil,
        update_comment: nil,
        user: instance_double('User', id: 1234, name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'will create a new comment if an existing one is not found' do
      expect(client).to receive(:add_comment)
      comment_on_pr
    end

    it 'will update an existing comment if one is found' do
      allow(client).to receive(:issue_comments).and_return([mock_comment])
      expect(client).to receive(:update_comment)
      comment_on_pr
    end

    it 'will not match text outside the reuseID tag' do
      allow(client).to receive(:issue_comments).and_return([mock_comment(body: 'test-id')])
      expect(client).to receive(:add_comment)
      comment_on_pr
    end

    it 'will not match comments belonging to other users' do
      allow(client).to receive(:issue_comments).and_return([mock_comment(user_id: 0)])
      expect(client).to receive(:add_comment)
      comment_on_pr
    end

    it 'will return the reuse identifier' do
      expect(comment_on_pr).to eq 'test-id'
    end

    def comment_on_pr
      helper = described_class.new(github_token: 'Fake-GitHubToken-123')
      helper.comment_on_pr(
        project_slug: 'test/test',
        pr_number: 1234,
        body: 'Test',
        reuse_identifier: 'test-id'
      )
    end

    def mock_comment(body: '<!-- REUSE_ID: test-id -->\n\nTest', user_id: 1234)
      instance_double('Comment', id: 1234, body: body, user: instance_double('User', id: user_id))
    end
  end

  describe '#initialize' do
    let(:client) do
      instance_double(
        Octokit::Client,
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    it 'properly passes the token all the way down to the Octokit::Client' do
      allow(Octokit::Client).to receive(:new).and_return(client)
      expect(Octokit::Client).to receive(:new).with(access_token: 'Fake-GitHubToken-123')
      described_class.new(github_token: 'Fake-GitHubToken-123')
    end
  end

  describe '#get_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_milestones) { [{ title: '9.8' }, { title: '10.1' }, { title: '10.1.3 ❄️' }] }
    let(:client) do
      instance_double(
        Octokit::Client,
        list_milestones: [],
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'properly passes the repository all the way down to the Octokit::Client' do
      expect(client).to receive(:list_milestones).with(test_repo)
      get_milestone(milestone_name: 'test')
    end

    it 'returns nil when no milestone is returned from the api' do
      milestone = get_milestone(milestone_name: '10')
      expect(milestone).to be_nil
    end

    it 'returns nil when no milestone title starts with the searched term' do
      allow(client).to receive(:list_milestones).and_return(test_milestones)
      milestone = get_milestone(milestone_name: '8.5')
      expect(milestone).to be_nil
    end

    it 'returns a milestone when the milestone title starts with search term' do
      allow(client).to receive(:list_milestones).and_return(test_milestones)
      milestone = get_milestone(milestone_name: '9')
      expect(milestone).to eq({ title: '9.8' })
    end

    it 'returns the milestone with the latest due date matching the search term when there are more than one' do
      allow(client).to receive(:list_milestones).and_return(test_milestones)
      milestone = get_milestone(milestone_name: '10.1')
      expect(milestone).to eq({ title: '10.1.3 ❄️' })
    end

    def get_milestone(milestone_name:)
      helper = described_class.new(github_token: 'Fake-GitHubToken-123')
      helper.get_milestone(test_repo, milestone_name)
    end
  end

  describe '#get_prs_and_issues_for_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:client) do
      instance_double(
        Octokit::Client,
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end
    let(:helper) do
      described_class.new(github_token: 'Fake-GitHubToken-123')
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'returns only opened PRs for a given milestone by default' do
      issue_results = [101].map { |num| sawyer_resource_stub(number: num) }
      pr_results = [103].map { |num| sawyer_resource_stub(number: num) }

      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} milestone:"12.3 New Version" is:issue is:open))
        .and_return({ items: issue_results })

      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} milestone:"12.3 New Version" is:pull-request is:open))
        .and_return({ items: pr_results })

      result = helper.get_prs_and_issues_for_milestone(repository: test_repo, milestone: '12.3 New Version')
      expect(result.map(&:number)).to eq([101, 103])
    end

    it 'returns only opened PRs for a given milestone if include_closed is false' do
      issue_results = [101].map { |num| sawyer_resource_stub(number: num) }
      pr_results = [103].map { |num| sawyer_resource_stub(number: num) }

      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} milestone:"12.3 New Version" is:issue is:open))
        .and_return({ items: issue_results })

      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} milestone:"12.3 New Version" is:pull-request is:open))
        .and_return({ items: pr_results })

      result = helper.get_prs_and_issues_for_milestone(repository: test_repo, milestone: '12.3 New Version', include_closed: false)
      expect(result.map(&:number)).to eq([101, 103])
    end

    it 'returns both opened and closed PRs of a milestone if include_closed is true' do
      issue_results = [101, 102].map { |num| sawyer_resource_stub(number: num) }
      pr_results = [103, 104].map { |num| sawyer_resource_stub(number: num) }

      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} milestone:"12.3 New Version" is:issue))
        .and_return({ items: issue_results })

      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} milestone:"12.3 New Version" is:pull-request))
        .and_return({ items: pr_results })

      result = helper.get_prs_and_issues_for_milestone(repository: test_repo, milestone: '12.3 New Version', include_closed: true)
      expect(result.map(&:number)).to eq([101, 102, 103, 104])
    end
  end

  describe '#set_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:client) do
      instance_double(
        Octokit::Client,
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end
    let(:helper) do
      described_class.new(github_token: 'Fake-GitHubToken-123')
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'updates the milestone as expected when everything is OK' do
      allow(client).to receive(:update_issue)
        .with(test_repo, 1337, { milestone: 42 })
        .and_return(sawyer_resource_stub(number: 1337))

      result = helper.set_milestone(
        repository: test_repo,
        number: 1337,
        milestone: 42
      )
      expect(result&.number).to eq(1337)
    end

    it 'raises a user_error! if PR number does not exist' do
      allow(client).to receive(:update_issue)
        .with(test_repo, 1337, { milestone: 42 })
        .and_raise(Octokit::NotFound)

      expect do
        helper.set_milestone(
          repository: test_repo,
          number: 1337,
          milestone: 42
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "Could not find PR or issue #1337 in #{test_repo}")
    end

    it 'raises a user_error! if the source milestone could not be found' do
      allow(client).to receive(:update_issue)
        .with(test_repo, 1337, { milestone: 42 })
        .and_raise(Octokit::UnprocessableEntity)

      expect do
        helper.set_milestone(
          repository: test_repo,
          number: 1337,
          milestone: 42
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Invalid milestone 42')
    end
  end

  describe '#create_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_milestone_number) { '10.0' }
    let(:test_milestone_duedate) { '2022-10-22T23:39:01Z' }
    let(:client) do
      instance_double(
        Octokit::Client,
        create_milestone: nil,
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'computes the correct dates for standard period' do
      due_date = '2022-12-02T08:00:00Z'.to_time.utc
      options = {
        due_on: '2022-12-02T12:00:00Z',
        description: "Code freeze: December 02, 2022\nApp Store submission: December 06, 2022\nRelease: December 09, 2022\n"
      }

      expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
      create_milestone(due_date: due_date, days_until_submission: 4, days_until_release: 7)
    end

    it 'computes the correct dates when submission and release dates are in the same day' do
      due_date = '2022-12-02T08:00:00Z'.to_time.utc
      options = {
        due_on: '2022-12-02T12:00:00Z',
        description: "Code freeze: December 02, 2022\nApp Store submission: December 03, 2022\nRelease: December 03, 2022\n"
      }

      expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
      create_milestone(due_date: due_date, days_until_submission: 1, days_until_release: 1)
    end

    it 'computes the correct dates when the due date is on the verge of a DST day change' do
      # Europe DST starts on the last Sunday of March, and ends on the last Sunday of October
      Time.use_zone('Europe/London') do
        # March 27th, 2022 is the exact day that London switches to the DST (+1h)
        # If the due date is too close to the next day, a day change will happen
        # So, 2022-03-27 23:00:00Z will be exactly 2022-03-28 00:00:00 +0100 at the DST change
        due_date = Time.zone.parse('2022-03-27 23:00:00Z')
        options = {
          due_on: '2022-03-28T12:00:00Z',
          description: "Code freeze: March 28, 2022\nApp Store submission: March 30, 2022\nRelease: March 31, 2022\n"
        }

        expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
        create_milestone(due_date: due_date, days_until_submission: 2, days_until_release: 3)
      end
    end

    it 'computes the correct dates when the due date is on DST but has no day change' do
      # Europe DST starts on the last Sunday of March, and ends on the last Sunday of October
      Time.use_zone('Europe/London') do
        # March 27th, 2022 is the exact day that London switches to the DST (+1h)
        # If the due date is not close enough at the day change, nothing will occur.
        # So, 2022-03-27 22:00:00Z will be exactly 2022-03-27 23:00:00 +0100 at the DST change.
        due_date = Time.zone.parse('2022-03-27 22:00:00Z')
        options = {
          due_on: '2022-03-27T12:00:00Z',
          description: "Code freeze: March 27, 2022\nApp Store submission: March 29, 2022\nRelease: March 30, 2022\n"
        }

        expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
        create_milestone(due_date: due_date, days_until_submission: 2, days_until_release: 3)
      end
    end

    it 'computes the correct dates when the due date is one day before a DST change' do
      # Europe DST starts on the last Sunday of March, and ends on the last Sunday of October
      Time.use_zone('Europe/London') do
        # As London changes to DST on March 27th, the date shouldn't be changed
        # So, 2022-03-26 23:00:00Z will be exactly 2022-03-26 23:00:00 +0000 at this Timezone.
        due_date = Time.zone.parse('2022-03-26 23:00:00Z')
        options = {
          due_on: '2022-03-26T12:00:00Z',
          description: "Code freeze: March 26, 2022\nApp Store submission: March 28, 2022\nRelease: March 29, 2022\n"
        }

        expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
        create_milestone(due_date: due_date, days_until_submission: 2, days_until_release: 3)
      end
    end

    it 'computes the correct dates when the offset is between DST endings' do
      # Europe DST starts on the last Sunday of March, and ends on the last Sunday of October
      Time.use_zone('Europe/London') do
        due_date = Time.zone.parse('2022-10-30 23:00:00Z')
        options = {
          due_on: '2022-10-30T12:00:00Z',
          description: "Code freeze: October 30, 2022\nApp Store submission: March 19, 2023\nRelease: March 25, 2023\n"
        }

        expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
        create_milestone(due_date: due_date, days_until_submission: 140, days_until_release: 146)
      end
    end

    it 'computes the correct dates when the release and submission dates are at the last day of a DST change' do
      # Europe DST starts on the last Sunday of March, and ends on the last Sunday of October
      Time.use_zone('Europe/London') do
        due_date = Time.zone.parse('2022-03-27 23:00:00Z')
        options = {
          due_on: '2022-03-28T12:00:00Z',
          description: "Code freeze: March 28, 2022\nApp Store submission: October 30, 2022\nRelease: October 31, 2022\n"
        }

        expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
        create_milestone(due_date: due_date, days_until_submission: 216, days_until_release: 217)
      end
    end

    it 'computes the correct dates when the due date is before Europe and USA DST changes and ends inside a DST period on Europe' do
      # USA DST starts on the second Sunday in March. and ends on the first Sunday in November
      # Europe DST starts on the last Sunday of March, and ends on the last Sunday in October
      Time.use_zone('Europe/London') do
        due_date = Time.zone.parse('2022-03-05 23:00:00Z')
        options = {
          due_on: '2022-03-05T12:00:00Z',
          description: "Code freeze: March 05, 2022\nApp Store submission: May 04, 2022\nRelease: May 05, 2022\n"
        }

        expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
        create_milestone(due_date: due_date, days_until_submission: 60, days_until_release: 61)
      end
    end

    it 'computes the correct dates when the due date is before Europe and USA DST changes and ends inside a DST period on USA' do
      # USA DST starts on the second Sunday in March. and ends on the first Sunday in November
      # Europe DST starts on the last Sunday of March, and ends on the last Sunday in October
      Time.use_zone('America/Los_Angeles') do
        due_date = Time.zone.parse('2022-03-05 23:00:00Z')
        options = {
          due_on: '2022-03-05T12:00:00Z',
          description: "Code freeze: March 05, 2022\nApp Store submission: May 04, 2022\nRelease: May 05, 2022\n"
        }

        expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
        create_milestone(due_date: due_date, days_until_submission: 60, days_until_release: 61)
      end
    end

    it 'raises an error if days_until_submission is less than or equal zero' do
      due_date = '2022-10-20T08:00:00Z'.to_time.utc
      expect { create_milestone(due_date: due_date, days_until_submission: 0, days_until_release: 5) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, 'days_until_submission must be greater than zero.')
    end

    it 'raises an error if days_until_release is less than or equal zero' do
      due_date = '2022-10-20T08:00:00Z'.to_time.utc
      expect { create_milestone(due_date: due_date, days_until_submission: 12, days_until_release: -8) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, 'days_until_release must be greater than zero.')
    end

    it 'raises an error if days_until_submission is greater than days_until_release' do
      due_date = '2022-10-20T08:00:00Z'.to_time.utc
      expect { create_milestone(due_date: due_date, days_until_submission: 14, days_until_release: 3) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, 'days_until_release must be greater or equal to days_until_submission.')
    end

    def create_milestone(due_date:, days_until_submission:, days_until_release:)
      helper = described_class.new(github_token: 'Fake-GitHubToken-123')
      helper.create_milestone(
        repository: test_repo,
        title: test_milestone_number,
        due_date: due_date,
        days_until_submission: days_until_submission,
        days_until_release: days_until_release
      )
    end
  end

  describe '#create_release' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_tag) { '1.0' }
    let(:test_target) { 'dummysha123456' }
    let(:release_url) { 'https://github.com/org/repo/releases/tag/1.2.3' }
    let(:test_description) { 'Hey Im a Test Description' }
    let(:client) do
      instance_double(
        Octokit::Client,
        create_release: nil,
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'has the correct options' do
      options = { body: test_description, draft: true, name: test_tag, prerelease: false, target_commitish: test_target }
      expect(client).to receive(:create_release).with(test_repo, test_tag, options)
      allow(client).to receive(:create_release).and_return(html_url: release_url)
      create_release(is_draft: true)
    end

    it 'uploads the assets to the correct location' do
      test_assets = 'test-file.xml'
      test_url = '/test/url'

      allow(client).to receive(:create_release).and_return({ url: test_url })
      expect(client).to receive(:upload_asset).with(test_url, test_assets, { content_type: 'application/octet-stream' })
      create_release(is_draft: true, assets: [test_assets])
    end

    it 'creates a draft release if is_draft is set to true' do
      options_draft_release = { body: test_description, draft: true, name: test_tag, prerelease: false, target_commitish: test_target }
      expect(client).to receive(:create_release).with(test_repo, test_tag, options_draft_release)
      allow(client).to receive(:create_release).and_return(html_url: release_url)
      url = create_release(is_draft: true)
      expect(url).to eq(release_url)
    end

    it 'creates a final (non-draft) release if is_draft is set to false' do
      options_final_release = { body: test_description, draft: false, name: test_tag, prerelease: false, target_commitish: test_target }
      expect(client).to receive(:create_release).with(test_repo, test_tag, options_final_release)
      allow(client).to receive(:create_release).and_return(html_url: release_url)
      url = create_release(is_draft: false)
      expect(url).to eq(release_url)
    end

    it 'uses a custom name when provided' do
      custom_name = 'Version 1.0'
      options = { body: test_description, draft: true, name: custom_name, prerelease: false, target_commitish: test_target }
      expect(client).to receive(:create_release).with(test_repo, test_tag, options)
      allow(client).to receive(:create_release).and_return(html_url: release_url)
      url = create_release(is_draft: true, name: custom_name)
      expect(url).to eq(release_url)
    end

    def create_release(is_draft:, assets: [], name: nil)
      helper = described_class.new(github_token: 'Fake-GitHubToken-123')
      helper.create_release(
        repository: test_repo,
        version: test_tag,
        name: name,
        target: test_target,
        description: test_description,
        assets: assets,
        prerelease: false,
        is_draft: is_draft
      )
    end
  end

  describe '#upload_release_assets' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_version) { '1.0.0' }
    let(:release_url) { 'https://api.github.com/repos/repo-test/project-test/releases/123' }
    let(:release_html_url) { 'https://github.com/repo-test/project-test/releases/tag/1.0.0' }
    let(:release) { sawyer_resource_stub(url: release_url, html_url: release_html_url, tag_name: test_version) }
    let(:existing_assets) { [] }
    let(:uploaded_asset) { release_asset(name: 'test-app.zip', url: 'https://api.github.com/repos/repo-test/project-test/releases/assets/999') }
    let(:client) do
      instance_double(
        Octokit::Client,
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end
    let(:helper) do
      described_class.new(github_token: 'Fake-GitHubToken-123')
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
      allow(client).to receive(:release_for_tag).with(test_repo, test_version).and_return(release)
      allow(client).to receive(:releases).with(test_repo).and_return([release])
      allow(client).to receive(:release_assets).with(release_url).and_return(existing_assets)
      allow(client).to receive_messages(upload_asset: uploaded_asset, delete_release_asset: true)
    end

    it 'fails clearly if the release does not exist' do
      allow(client).to receive(:release_for_tag).with(test_repo, test_version).and_raise(Octokit::NotFound)
      allow(client).to receive(:releases).with(test_repo).and_return([])

      with_tmp_file(named: 'test-app.zip') do |file_path|
        expect do
          upload_release_assets(assets: [file_path])
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "Could not find GitHub Release for tag #{test_version} in #{test_repo}")
      end
    end

    it 'fails clearly if an asset file does not exist' do
      expect(client).not_to receive(:releases)
      expect(client).not_to receive(:release_assets)
      expect(client).not_to receive(:upload_asset)

      expect do
        upload_release_assets(assets: ['missing-file.zip'])
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "Can't find file missing-file.zip!")
    end

    it 'fails clearly if an asset is not a file path' do
      expect(client).not_to receive(:releases)
      expect(client).not_to receive(:release_assets)
      expect(client).not_to receive(:upload_asset)

      expect do
        upload_release_assets(assets: [123])
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'release_assets must contain file paths')
    end

    it 'fails without mutating GitHub when local assets have duplicate filenames' do
      in_tmp_dir do |tmpdir|
        first_dir = File.join(tmpdir, 'ios')
        second_dir = File.join(tmpdir, 'tvos')
        Dir.mkdir(first_dir)
        Dir.mkdir(second_dir)

        first_file_path = File.join(first_dir, 'test-app.zip')
        second_file_path = File.join(second_dir, 'test-app.zip')
        File.write(first_file_path, 'ios')
        File.write(second_file_path, 'tvos')

        expect(client).not_to receive(:releases)
        expect(client).not_to receive(:release_assets)
        expect(client).not_to receive(:delete_release_asset)
        expect(client).not_to receive(:upload_asset)

        expect do
          upload_release_assets(assets: [first_file_path, second_file_path], replace_existing: false)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'release_assets must not contain duplicate filenames')
      end
    end

    it 'uploads assets to a draft release' do
      draft_release = sawyer_resource_stub(url: release_url, html_url: release_html_url, tag_name: test_version, draft: true)
      other_release = sawyer_resource_stub(url: 'https://api.github.com/repos/repo-test/project-test/releases/456', html_url: 'https://github.com/repo-test/project-test/releases/tag/0.9.0', tag_name: '0.9.0')

      allow(client).to receive(:release_for_tag).with(test_repo, test_version).and_raise(Octokit::NotFound)
      allow(client).to receive(:releases).with(test_repo).and_return([other_release, draft_release])
      allow(client).to receive(:release_assets).with(release_url).and_return([])

      with_tmp_file(named: 'test-app.zip') do |file_path|
        expect(client).to receive(:upload_asset).with(release_url, file_path, { content_type: 'application/octet-stream' })

        result = upload_release_assets(assets: [file_path])

        expect(result).to eq(release_html_url)
      end
    end

    it 'uses the release list if available' do
      draft_release = sawyer_resource_stub(url: 'draft-api-url', html_url: 'draft-html-url', tag_name: test_version, draft: true)

      allow(client).to receive(:releases).with(test_repo).and_return([draft_release])
      expect(client).not_to receive(:release_for_tag)
      allow(client).to receive(:release_assets).with(draft_release.url).and_return([])

      with_tmp_file(named: 'test-app.zip') do |file_path|
        expect(client).to receive(:upload_asset).with(draft_release.url, file_path, { content_type: 'application/octet-stream' })

        result = upload_release_assets(assets: [file_path])

        expect(result).to eq(draft_release.html_url)
      end
    end

    it 'falls back to the direct release-by-tag lookup when the release list misses' do
      with_tmp_file(named: 'test-app.zip') do |file_path|
        allow(client).to receive(:releases).with(test_repo).and_return([])
        allow(client).to receive(:release_for_tag).with(test_repo, test_version).and_return(release)
        expect(client).to receive(:upload_asset).with(release_url, file_path, { content_type: 'application/octet-stream' })

        result = upload_release_assets(assets: [file_path])

        expect(result).to eq(release_html_url)
      end
    end

    it 'uploads one asset to the existing release' do
      with_tmp_file(named: 'test-app.zip') do |file_path|
        expect(client).to receive(:upload_asset).with(release_url, file_path, { content_type: 'application/octet-stream' })

        result = upload_release_assets(assets: [file_path])

        expect(result).to eq(release_html_url)
      end
    end

    it 'uploads multiple assets to the existing release' do
      in_tmp_dir do |tmpdir|
        first_file_path = File.join(tmpdir, 'test-ios.zip')
        second_file_path = File.join(tmpdir, 'test-tvos.zip')
        File.write(first_file_path, 'ios')
        File.write(second_file_path, 'tvos')

        first_uploaded_asset = release_asset(name: 'test-ios.zip', url: 'https://api.github.com/repos/repo-test/project-test/releases/assets/1000')
        second_uploaded_asset = release_asset(name: 'test-tvos.zip', url: 'https://api.github.com/repos/repo-test/project-test/releases/assets/1001')

        expect(client).to receive(:upload_asset).with(release_url, first_file_path, { content_type: 'application/octet-stream' }).ordered.and_return(first_uploaded_asset)
        expect(client).to receive(:upload_asset).with(release_url, second_file_path, { content_type: 'application/octet-stream' }).ordered.and_return(second_uploaded_asset)

        result = upload_release_assets(assets: [first_file_path, second_file_path])

        expect(result).to eq(release_html_url)
      end
    end

    it 'replaces an existing asset with the same filename' do
      existing_asset = release_asset(name: 'test-app.zip', url: 'https://api.github.com/repos/repo-test/project-test/releases/assets/1234')
      allow(client).to receive(:release_assets).with(release_url).and_return([existing_asset])

      with_tmp_file(named: 'test-app.zip') do |file_path|
        expect(client).to receive(:delete_release_asset).with(existing_asset.url)
        expect(client).to receive(:upload_asset).with(release_url, file_path, { content_type: 'application/octet-stream' })

        result = upload_release_assets(assets: [file_path])

        expect(result).to eq(release_html_url)
      end
    end

    it 'preserves unrelated existing assets' do
      matching_asset = release_asset(name: 'test-app.zip', url: 'https://api.github.com/repos/repo-test/project-test/releases/assets/1234')
      unrelated_asset = release_asset(name: 'other-platform.zip', url: 'https://api.github.com/repos/repo-test/project-test/releases/assets/5678')
      deleted_asset_urls = []

      allow(client).to receive(:release_assets).with(release_url).and_return([matching_asset, unrelated_asset])
      allow(client).to receive(:delete_release_asset) do |asset_url|
        deleted_asset_urls << asset_url
        true
      end

      with_tmp_file(named: 'test-app.zip') do |file_path|
        upload_release_assets(assets: [file_path])
      end

      expect(deleted_asset_urls).to eq([matching_asset.url])
    end

    it 'fails without deleting or uploading when replace_existing is false and a matching asset exists' do
      existing_asset = release_asset(name: 'test-app.zip', url: 'https://api.github.com/repos/repo-test/project-test/releases/assets/1234')
      allow(client).to receive(:release_assets).with(release_url).and_return([existing_asset])

      expect(client).not_to receive(:delete_release_asset)
      expect(client).not_to receive(:upload_asset)

      with_tmp_file(named: 'test-app.zip') do |file_path|
        expect do
          upload_release_assets(assets: [file_path], replace_existing: false)
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "GitHub Release #{test_version} already has an asset named test-app.zip. Set replace_existing: true to replace it.")
      end
    end

    def upload_release_assets(assets:, replace_existing: true)
      helper.upload_release_assets(
        repository: test_repo,
        version: test_version,
        assets: assets,
        replace_existing: replace_existing
      )
    end

    def release_asset(name:, url:)
      sawyer_resource_stub(name: name, url: url)
    end
  end

  describe '#github_token_config_item' do
    it 'has the correct key' do
      expect(described_class.github_token_config_item.key).to eq(:github_token)
    end

    it 'has the correct env_name' do
      expect(described_class.github_token_config_item.env_name).to eq('GITHUB_TOKEN')
    end

    it 'has the correct description' do
      expect(described_class.github_token_config_item.description).to eq('The GitHub OAuth access token')
    end

    it 'is not optional' do
      expect(described_class.github_token_config_item.optional).to be(false)
    end

    it 'has String as data_type' do
      expect(described_class.github_token_config_item.data_type).to eq(String)
    end
  end
end
