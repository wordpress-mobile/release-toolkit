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
end
