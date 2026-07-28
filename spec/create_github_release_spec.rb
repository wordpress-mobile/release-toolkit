# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::CreateGithubReleaseAction do
  let(:test_token) { 'ghp_fake_token' }
  let(:test_repo) { 'repo-test/project-test' }
  let(:test_version) { '1.0.0' }
  let(:release_url) { 'https://github.com/repo-test/project-test/releases/tag/1.0.0' }
  let(:github_helper) { instance_double(Fastlane::Helper::GithubHelper) }

  before do
    allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
  end

  context 'when no release notes file is provided' do
    it 'creates the release with an empty description' do
      expect(github_helper).to receive(:create_release).with(
        repository: test_repo,
        version: test_version,
        name: nil,
        target: nil,
        description: '',
        assets: [],
        prerelease: false,
        is_draft: true
      ).and_return(release_url)

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        version: test_version,
        release_assets: []
      )

      expect(result).to eq(release_url)
    end
  end

  context 'when a release notes file is provided' do
    it 'rewrites bracketed GitHub PR and issue URLs to shorthand' do
      notes = <<~NOTES
        - Fix a thing [https://github.com/org-test/other-repo/pull/123]
        - Fix another thing [https://github.com/org-test/other-repo/issues/456]
        - Leave markdown links alone [as a link](https://github.com/org-test/other-repo/pull/789)
      NOTES

      expected_description = <<~NOTES
        - Fix a thing [org-test/other-repo#123]
        - Fix another thing [org-test/other-repo#456]
        - Leave markdown links alone [as a link](https://github.com/org-test/other-repo/pull/789)
      NOTES

      with_tmp_file(named: 'release-notes.txt', content: notes) do |notes_path|
        expect(github_helper).to receive(:create_release).with(
          repository: test_repo,
          version: test_version,
          name: nil,
          target: nil,
          description: expected_description,
          assets: [],
          prerelease: false,
          is_draft: true
        ).and_return(release_url)

        result = run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          version: test_version,
          release_assets: [],
          release_notes_file_path: notes_path
        )

        expect(result).to eq(release_url)
      end
    end
  end
end
