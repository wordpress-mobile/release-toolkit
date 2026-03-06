# frozen_string_literal: true

require_relative 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::UpdateAppsCdnBuildMetadataAction do
  let(:test_site_id) { '12345678' }
  let(:test_post_id) { 98_765 }
  let(:second_post_id) { 54_321 }
  let(:api_url) { "https://public-api.wordpress.com/wp/v2/sites/#{test_site_id}/a8c_cdn_build/#{test_post_id}" }
  let(:second_api_url) { "https://public-api.wordpress.com/wp/v2/sites/#{test_site_id}/a8c_cdn_build/#{second_post_id}" }
  let(:visibility_term_url) { "https://public-api.wordpress.com/wp/v2/sites/#{test_site_id}/visibility" }
  let(:test_api_token) { 'test_api_token' }

  let(:external_term_id) { 21_293 }
  let(:internal_term_id) { 1_316 }

  let(:stub_success_response) do
    {
      id: test_post_id,
      title: { rendered: 'WordPress.com Studio 1.7.5' },
      status: 'publish',
      visibility: [external_term_id],
      class_list: ['visibility-external']
    }.to_json
  end

  before do
    WebMock.disable_net_connect!
  end

  describe 'updating visibility' do
    it 'successfully updates the visibility to external' do
      stub_request(:get, visibility_term_url)
        .with(query: { 'slug' => 'external' })
        .to_return(
          status: 200,
          body: [{ 'id' => external_term_id, 'name' => 'External', 'slug' => 'external' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

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
      expect(results.first[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          expect(req.headers['Authorization']).to eq("Bearer #{test_api_token}")
          expect(req.headers['Content-Type']).to eq('application/json')
          body = JSON.parse(req.body)
          expect(body['visibility']).to eq([external_term_id])
          true
        end
      )
    end

    it 'successfully updates the visibility to internal' do
      stub_request(:get, visibility_term_url)
        .with(query: { 'slug' => 'internal' })
        .to_return(
          status: 200,
          body: [{ 'id' => internal_term_id, 'name' => 'Internal', 'slug' => 'internal' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      internal_response = {
        id: test_post_id,
        visibility: [internal_term_id],
        class_list: ['visibility-internal']
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

      expect(results.first[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          body = JSON.parse(req.body)
          expect(body['visibility']).to eq([internal_term_id])
          true
        end
      )
    end
  end

  describe 'batch updating multiple posts' do
    it 'updates all posts with a single visibility term lookup' do
      stub_request(:get, visibility_term_url)
        .with(query: { 'slug' => 'external' })
        .to_return(
          status: 200,
          body: [{ 'id' => external_term_id, 'name' => 'External', 'slug' => 'external' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

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
      expect(results.map { |r| r[:post_id] }).to eq([test_post_id, second_post_id])

      # Visibility term lookup should have been called only once
      expect(WebMock).to have_requested(:get, visibility_term_url).with(query: { 'slug' => 'external' }).once
      expect(WebMock).to have_requested(:post, api_url).once
      expect(WebMock).to have_requested(:post, second_api_url).once
    end
  end

  describe 'updating post_status' do
    it 'successfully updates the post_status' do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: { id: test_post_id, status: 'draft' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      results = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_ids: [test_post_id],
        post_status: 'draft'
      )

      expect(results.first[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          body = JSON.parse(req.body)
          expect(body['status']).to eq('draft')
          true
        end
      )
    end
  end

  describe 'updating multiple fields' do
    it 'successfully updates both visibility and post_status' do
      stub_request(:get, visibility_term_url)
        .with(query: { 'slug' => 'external' })
        .to_return(
          status: 200,
          body: [{ 'id' => external_term_id, 'name' => 'External', 'slug' => 'external' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

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

      expect(results.first[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          body = JSON.parse(req.body)
          expect(body['visibility']).to eq([external_term_id])
          expect(body['status']).to eq('publish')
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
          body: { code: 'rest_forbidden', message: 'You are not authorized.' }.to_json,
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

    it 'handles visibility term lookup failure' do
      stub_request(:get, visibility_term_url)
        .with(query: { 'slug' => 'external' })
        .to_return(
          status: 200,
          body: [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_ids: [test_post_id],
          visibility: :external
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "No visibility term found for 'external'")
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
