# frozen_string_literal: true

require_relative 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::UpdateAppsCdnBuildMetadataAction do
  let(:test_site_id) { '12345678' }
  let(:test_post_id) { 98_765 }
  let(:second_post_id) { 54_321 }
  let(:api_url) { "https://public-api.wordpress.com/wpcom/v2/sites/#{test_site_id}/a8c-cdn/builds/#{test_post_id}" }
  let(:second_api_url) { "https://public-api.wordpress.com/wpcom/v2/sites/#{test_site_id}/a8c-cdn/builds/#{second_post_id}" }
  let(:test_api_token) { 'test_api_token' }

  let(:stub_success_response) do
    {
      id: test_post_id,
      post_status: 'publish',
      release_notes: 'Release 1.7.5',
      visibility: 'External',
      product: 'WordPress.com Studio'
    }.to_json
  end

  before do
    WebMock.disable_net_connect!
  end

  describe 'updating visibility' do
    it 'successfully updates the visibility to external' do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: stub_success_response,
          headers: { 'Content-Type' => 'application/json' }
        )

      results = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_ids: [test_post_id],
        visibility: :external
      )

      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
      expect(results.first).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          expect(req.headers['Authorization']).to eq("Bearer #{test_api_token}")
          expect(req.headers['Content-Type']).to eq('application/json')
          body = JSON.parse(req.body)
          expect(body['visibility']).to eq('External')
          true
        end
      )
    end

    it 'successfully updates the visibility to internal' do
      internal_response = {
        id: test_post_id,
        post_status: 'publish',
        visibility: 'Internal'
      }.to_json

      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: internal_response,
          headers: { 'Content-Type' => 'application/json' }
        )

      results = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_ids: [test_post_id],
        visibility: :internal
      )

      expect(results.first).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          body = JSON.parse(req.body)
          expect(body['visibility']).to eq('Internal')
          true
        end
      )
    end
  end

  describe 'batch updating multiple posts' do
    it 'updates each post with a single request' do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: { id: test_post_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:post, second_api_url)
        .to_return(
          status: 200,
          body: { id: second_post_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      results = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_ids: [test_post_id, second_post_id],
        visibility: :external
      )

      expect(results.size).to eq(2)
      expect(results).to eq([test_post_id, second_post_id])

      expect(WebMock).to have_requested(:post, api_url).once
      expect(WebMock).to have_requested(:post, second_api_url).once
    end
  end

  describe 'updating post_status' do
    it 'successfully updates the post_status' do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: { id: test_post_id, post_status: 'draft' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      results = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_ids: [test_post_id],
        post_status: 'draft'
      )

      expect(results.first).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          body = JSON.parse(req.body)
          expect(body['post_status']).to eq('draft')
          true
        end
      )
    end
  end

  describe 'updating multiple fields' do
    it 'successfully updates both visibility and post_status' do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: stub_success_response,
          headers: { 'Content-Type' => 'application/json' }
        )

      results = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_ids: [test_post_id],
        visibility: :external,
        post_status: 'publish'
      )

      expect(results.first).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          body = JSON.parse(req.body)
          expect(body['visibility']).to eq('External')
          expect(body['post_status']).to eq('publish')
          true
        end
      )
    end
  end

  describe 'error handling' do
    it 'handles API errors properly' do
      stub_request(:post, api_url)
        .to_return(
          status: 403,
          body: { code: 'rest_forbidden', message: 'You do not have permission to update builds.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [test_post_id],
          post_status: 'publish'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "Update of Apps CDN build metadata failed for post #{test_post_id}")
    end

    it 'handles a non-existent build post properly' do
      stub_request(:post, api_url)
        .to_return(
          status: 404,
          body: { code: 'rest_build_not_found', message: 'Build not found.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [test_post_id],
          visibility: :external
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "Update of Apps CDN build metadata failed for post #{test_post_id}")
    end

    it 'handles server errors properly' do
      stub_request(:post, api_url)
        .to_return(
          status: 500,
          body: 'Internal Server Error',
          headers: { 'Content-Type' => 'text/plain' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [test_post_id],
          post_status: 'publish'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "Update of Apps CDN build metadata failed for post #{test_post_id}")
    end
  end

  describe 'parameter validation' do
    it 'fails if site_id is empty' do
      expect do
        run_described_fastlane_action(
          site_id: '',
          api_token: test_api_token,
          post_ids: [test_post_id],
          post_status: 'publish'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Site ID cannot be empty')
    end

    it 'fails if api_token is empty' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: '',
          post_ids: [test_post_id],
          post_status: 'publish'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'API token cannot be empty')
    end

    it 'fails if post_ids is a single integer instead of an array' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: test_post_id,
          post_status: 'publish'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /value must be either `Array` or `comma-separated String`/)
    end

    it 'fails if post_ids is empty' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [],
          post_status: 'publish'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Post IDs must be a non-empty array')
    end

    it 'fails if post_ids contains a non-positive integer' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [-1],
          post_status: 'publish'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Each post ID must be a positive integer, got: -1')
    end

    it 'fails if visibility is not a valid symbol' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [test_post_id],
          visibility: :public
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Visibility must be one of: `:internal`, `:external`')
    end

    it 'fails if post_status is not a valid value' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [test_post_id],
          post_status: 'invalid_status'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Post status must be one of: publish, draft')
    end

    it 'fails if no metadata to update is provided' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [test_post_id]
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'No metadata to update. Provide at least one of: visibility, post_status')
    end
  end
end
