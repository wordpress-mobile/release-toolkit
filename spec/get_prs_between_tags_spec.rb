require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::GetPrsBetweenTagsAction do
  let(:test_token) { 'ghp_fake_token' }
  let(:test_repo) { 'repo-test/project-test' }
  let(:test_tag_name) { '12.3' }
  let(:test_head_ref) { 'abc1234' }
  let(:client) do
    instance_double(
      Octokit::Client,
      user: instance_double('User', name: 'test'),
      'auto_paginate=': nil
    )
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
    allow(client).to receive(:release_for_tag) do |repo, tag|
      double(html_url: "https://github.com/#{repo}/releases/tag/#{tag}") # rubocop:disable RSpec/VerifiedDoubles
    end
    allow(described_class).to receive(:`).with('git rev-parse HEAD').and_return(test_head_ref)
  end

  context 'when providing valid parameters' do
    def test_with_params(target_commitish: nil, previous_tag: nil, configuration_file_path: nil)
      # Arrange
      changelog = <<~CHANGELOG
        ### Breaking Changes
        * Add configuration item for .xcconfig file in `ios_get_app_version` by @iangmaia in https://github.com/wordpress-mobile/release-toolkit/pull/445
        * Remove legacy localisation script references and actions by @iangmaia in https://github.com/wordpress-mobile/release-toolkit/pull/447
        * Remove Deliverfile related functionality by @iangmaia in https://github.com/wordpress-mobile/release-toolkit/pull/450
        ### New Features
        * Add `if_exists` config to `upload_to_s3` by @mokagio in https://github.com/wordpress-mobile/release-toolkit/pull/495
        * Make create_release print & return the release URL by @AliSoftware in https://github.com/wordpress-mobile/release-toolkit/pull/503
        * Support Ruby 3.2.2 by @crazytonyli in https://github.com/wordpress-mobile/release-toolkit/pull/492
        ### Bug Fixes & Internal Changes
        * Update dependencies: `octokit`, `buildkite-test_collector` and `danger` by @spencertransier in https://github.com/wordpress-mobile/release-toolkit/pull/491
        * Require version_code parameter to be an Integer for Android hotfixes by @mokagio in https://github.com/wordpress-mobile/release-toolkit/pull/167


        **Full Changelog**: https://github.com/{test_repo}/compare/#{previous_tag}...#{test_tag_name}
      CHANGELOG

      http_result = <<~HTTP_RESULT
        ## What's Changed
        #{changelog}
      HTTP_RESULT

      allow(client).to receive(:post).with(
        "repos/#{test_repo}/releases/generate-notes",
        config_file_path: configuration_file_path,
        previous_tag_name: previous_tag,
        tag_name: test_tag_name,
        target_commitish: target_commitish || test_head_ref
      ).and_return(double(body: http_result)) # rubocop:disable RSpec/VerifiedDoubles

      # Act
      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        tag_name: test_tag_name,
        target_commitish: target_commitish,
        previous_tag: previous_tag,
        configuration_file_path: configuration_file_path
      )

      # Assert
      last = previous_tag.nil? ? 'last release' : "[#{previous_tag}](https://github.com/#{test_repo}/releases/tag/#{previous_tag})"
      action_result = <<~ACTION_RESULT
        ## New PRs since #{last}

        #{changelog}
      ACTION_RESULT
      expect(result).to eq(action_result)
    end

    it 'allows to provide both `previous_tag` and `target_commitish`' do
      test_with_params(
        target_commitish: 'trunk',
        previous_tag: '12.2'
      )
    end

    it 'allows to omit the `previous_tag`' do
      # In this case the GitHub API call will use the tag of the latest release to compute the release notes
      test_with_params(
        target_commitish: 'trunk'
      )
    end

    it 'allows to omit the `target_commitish` and uses HEAD sha1 as default' do
      test_with_params(
        previous_tag: '12.2'
      )
    end

    it 'allows to provide a custom `configuration_file_path`' do
      test_with_params(
        target_commitish: 'trunk',
        previous_tag: '12.2',
        configuration_file_path: '.github/generated-release-config.yml'
      )
    end
  end

  describe 'error handling' do
    def test_with_params(target_commitish: nil, previous_tag: nil, configuration_file_path: nil, error_msg: 'API Failure')
      # Arrange
      allow(client).to receive(:post).with(
        "repos/#{test_repo}/releases/generate-notes",
        config_file_path: configuration_file_path,
        previous_tag_name: previous_tag,
        tag_name: test_tag_name,
        target_commitish: target_commitish || test_head_ref
      ).and_raise(StandardError, error_msg)

      # Act
      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        tag_name: test_tag_name,
        target_commitish: target_commitish,
        previous_tag: previous_tag,
        configuration_file_path: configuration_file_path
      )

      # Assert
      expect(result).to eq("❌ Error computing the list of PRs since #{previous_tag || 'last release'}: `#{error_msg}`")
    end

    context 'when using an invalid `target_commitish` while the `tag_name` does not exist' do
      it 'returns an error message referencing the `previous_tag` if one was provided' do
        test_with_params(
          previous_tag: '12.2',
          target_commitish: 'non-existing-ref',
          error_msg: '400 - Invalid target_commitish parameter'
        )
      end

      it 'returns a generic error message if no `previous_tag` was provided' do
        test_with_params(
          target_commitish: 'non-existing-ref',
          error_msg: '400 - Invalid target_commitish parameter'
        )
      end
    end

    it 'returns an error message if the `previous_tag` does not exist' do
      test_with_params(
        previous_tag: '12.2',
        error_msg: '400 - Invalid previous_tag parameter'
      )
    end
  end
end
