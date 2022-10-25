require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Helper::GithubHelper do
  describe '#initialize' do
    let(:client) do
      instance_double(
        Octokit::Client,
        user: instance_double('User', name: 'test'),
        'auto_paginate=': nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    it 'with the correct github_token' do
      expect(described_class).to receive(:new).with(github_token: 'GITHUB_TOKEN')
      described_class.new(github_token: 'GITHUB_TOKEN')
    end

    it 'Octokit client receives the correct github_token' do
      expect(Octokit::Client).to receive(:new).with(access_token: 'GITHUB_TOKEN')
      described_class.new(github_token: 'GITHUB_TOKEN')
    end
  end

  describe 'download_file_from_tag' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_tag) { '1.0' }
    let(:test_file) { 'test-folder/test-file.xml' }
    let(:content_url) { "https://api.github.com/repos/#{test_repo}/contents/#{test_file}?ref=#{test_tag}" }
    let(:client) do
      instance_double(
        Octokit::Client,
        contents: double(download_url: content_url) # rubocop:disable RSpec/VerifiedDoubles
      )
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    it 'fails if it does not find the right release on GitHub' do
      stub = stub_request(:get, content_url).to_return(status: [404, 'Not Found'])
      expect(described_class.download_file_from_tag(repository: test_repo, tag: test_tag, file_path: test_file, download_folder: './')).to be_nil
      expect(stub).to have_been_made.once
    end

    it 'writes the raw content to a file' do
      stub = stub_request(:get, content_url).to_return(status: 200, body: 'my-test-content')
      Dir.mktmpdir('a8c-download-repo-file-') do |tmpdir|
        dst_file = File.join(tmpdir, 'test-file.xml')
        expect(described_class.download_file_from_tag(repository: test_repo, tag: test_tag, file_path: test_file, download_folder: tmpdir)).to eq(dst_file)
        expect(stub).to have_been_made.once
        expect(File.read(dst_file)).to eq('my-test-content')
      end
    end
  end

  describe 'get_last_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:last_stone) { mock_milestone('10.0') }
    let(:client) do
      instance_double(
        Octokit::Client,
        list_milestones: ['9.8 ❄️', '9.9'].map { |title| mock_milestone(title) }.append(last_stone)
      )
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    it 'returns correct milestone' do
      expect(client).to receive(:list_milestones)
      expect(described_class.get_last_milestone(repository: test_repo)).to eq(last_stone)
    end

    def mock_milestone(title)
      { title: title }
    end
  end

  describe 'comment_on_pr' do
    let(:client) do
      instance_double(
        Octokit::Client,
        issue_comments: [],
        add_comment: nil,
        update_comment: nil,
        user: instance_double('User', id: 1234)
      )
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
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
      described_class.comment_on_pr(
        project_slug: 'test/test',
        pr_number: 1234,
        body: 'Test',
        reuse_identifier: 'test-id'
      )
    end

    def mock_comment(body: '<!-- REUSE_ID: test-id --> Test', user_id: 1234)
      instance_double('Comment', id: 1234, body: body, user: instance_double('User', id: user_id))
    end
  end

  describe 'get_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:release_name) { '10.0' }
    let(:client) do
      instance_double(
        Octokit::Client,
        list_milestones: []
      )
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    it 'receives the correct repository' do
      expect(client).to receive(:list_milestones).with(test_repo)
      described_class.get_milestone(test_repo, release_name)
    end

    it 'returns nil when no milestone exists' do
      expect(described_class.get_milestone(test_repo, release_name)).to be_nil
    end

    it 'returns milestone from repo' do
      allow(client).to receive(:list_milestones).and_return([{ title: 'release/10.0' }])
      expect(described_class.get_milestone(test_repo, release_name)).to be_nil
    end
  end

  describe 'create_milestone' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_milestone_number) { '10.0' }
    let(:test_milestone_duedate) { '2022-10-22T23:39:01Z' }
    let(:client) do
      instance_double(
        Octokit::Client,
        create_milestone: nil
      )
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    it 'has the correct dates to code freeze without submission' do
      comment = "Code freeze: October 22, 2022\nApp Store submission: November 15, 2022\nRelease: October 25, 2022\n"
      options = { due_on: '2022-10-22T12:00:00Z', description: comment }

      expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
      create_milestone(need_submission: false, milestone_duration: 24, days_code_freeze: 3)
    end

    it 'has the correct dates to code freeze with submission' do
      comment = "Code freeze: October 22, 2022\nApp Store submission: October 22, 2022\nRelease: October 25, 2022\n"
      options = { due_on: '2022-10-22T12:00:00Z', description: comment }

      expect(client).to receive(:create_milestone).with(test_repo, test_milestone_number, options)
      create_milestone(need_submission: true, milestone_duration: 19, days_code_freeze: 3)
    end

    def create_milestone(need_submission:, milestone_duration:, days_code_freeze:)
      described_class.create_milestone(
        test_repo,
        test_milestone_number,
        test_milestone_duedate.to_time.utc,
        milestone_duration,
        days_code_freeze,
        need_submission
      )
    end
  end

  describe 'create_release' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_tag) { '1.0' }
    let(:test_target) { 'dummysha123456' }
    let(:test_description) { 'Hey Im a Test Description' }
    let(:client) do
      instance_double(
        Octokit::Client,
        create_release: nil
      )
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    it 'has the correct options' do
      options = { body: test_description, draft: true, name: test_tag, prerelease: false, target_commitish: test_target }
      expect(client).to receive(:create_release).with(test_repo, test_tag, options)
      mockrelease
    end

    it 'upload the assets to the correct location' do
      test_assets = 'test-file.xml'
      test_url = '/test/url'

      allow(client).to receive(:create_release).and_return({ url: test_url })
      expect(client).to receive(:upload_asset).with(test_url, test_assets, { content_type: 'application/octet-stream' })
      mockrelease([test_assets])
    end

    def mockrelease(assets = [])
      described_class.create_release(
        repository: test_repo,
        version: test_tag,
        target: test_target,
        description: test_description,
        assets: assets,
        prerelease: false
      )
    end
  end

  describe 'github_token_config_item' do
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
      expect(described_class.github_token_config_item.optional).to eq(false)
    end
    it 'has String as data_type' do
      expect(described_class.github_token_config_item.data_type).to eq(String)
    end
  end
end
