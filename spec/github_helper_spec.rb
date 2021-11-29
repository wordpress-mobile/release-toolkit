require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Helper::GithubHelper do
  describe 'download_file_from_tag' do
    it 'fails if it does not find the right release on GitHub' do
      stub = stub_request(:get, 'https://raw.githubusercontent.com/repo-test/project-test/1.0/test-file.xml').to_return(status: [404, 'Not Found'])
      expect(described_class.download_file_from_tag(repository: 'repo-test/project-test', tag: '1.0', file_path: 'test-file.xml', download_folder: './')).to be_nil
      expect(stub).to have_been_made.once
    end

    it 'writes the raw content to a file' do
      stub = stub_request(:get, 'https://raw.githubusercontent.com/repo-test/project-test/1.0/test-file.xml').to_return(status: 200, body: 'my-test-content')
      Dir.mktmpdir('a8c-download-repo-file-') do |tmpdir|
        dst_file = File.join(tmpdir, 'test-file.xml')
        expect(described_class.download_file_from_tag(repository: 'repo-test/project-test', tag: '1.0', file_path: 'test-file.xml', download_folder: tmpdir)).to eq(dst_file)
        expect(stub).to have_been_made.once
        expect(File.read(dst_file)).to eq('my-test-content')
      end
    end
  end

  describe 'github_token' do
    after do
      ENV['GHHELPER_ACCESS'] = nil
      ENV['GITHUB_TOKEN'] = nil
    end

    it 'can use `GHHELPER_ACCESS`' do
      ENV['GHHELPER_ACCESS'] = 'GHHELPER_ACCESS'
      expect(described_class.github_token).to eq('GHHELPER_ACCESS')
    end

    it 'can use `GITHUB_TOKEN`' do
      ENV['GITHUB_TOKEN'] = 'GITHUB_TOKEN'
      expect(described_class.github_token).to eq('GITHUB_TOKEN')
    end

    it 'prioritizes GHHELPER_ACCESS` over `GITHUB_TOKEN` if both are present' do
      ENV['GITHUB_TOKEN'] = 'GITHUB_TOKEN'
      ENV['GHHELPER_ACCESS'] = 'GHHELPER_ACCESS'
      expect(described_class.github_token).to eq('GHHELPER_ACCESS')
    end

    it 'prints an error if no environment variable is present' do
      expect { described_class.github_token }.to raise_error(FastlaneCore::Interface::FastlaneError)
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
      allow(described_class).to receive(:github_client).and_return(client)
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
