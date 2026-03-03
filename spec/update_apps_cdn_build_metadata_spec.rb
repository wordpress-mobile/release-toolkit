# frozen_string_literal: true

require_relative 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::UpdateAppsCdnBuildMetadataAction do
  let(:test_site_id) { '12345678' }
  let(:test_post_id) { 98_765 }
  let(:api_url) { "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/posts/#{test_post_id}" }
  let(:test_api_token) { 'test_api_token' }

  let(:stub_success_response) do
    {
      ID: test_post_id,
      title: 'WordPress.com Studio 1.7.5',
      status: 'publish',
      terms: {
        visibility: {
          External: { ID: 1, name: 'External', slug: 'external' }
        }
      }
    }.to_json
  end

  before do
    WebMock.disable_net_connect!
  end

  after do
    WebMock.allow_net_connect!
  end

  describe 'updating visibility' do
    it 'successfully updates the visibility to external' do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: stub_success_response,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_id: test_post_id,
        visibility: :external
      )

      expect(result).to be_a(Hash)
      expect(result[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          expect(req.headers['Authorization']).to eq("Bearer #{test_api_token}")
          expect(req.headers['Content-Type']).to eq('application/x-www-form-urlencoded')
          expect(req.body).to include('terms%5Bvisibility%5D=External')
          true
        end
      )
    end

    it 'successfully updates the visibility to internal' do
      internal_response = {
        ID: test_post_id,
        terms: {
          visibility: {
            Internal: { ID: 2, name: 'Internal', slug: 'internal' }
          }
        }
      }.to_json

      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: internal_response,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_id: test_post_id,
        visibility: :internal
      )

      expect(result[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          expect(req.body).to include('terms%5Bvisibility%5D=Internal')
          true
        end
      )
    end
  end

  describe 'updating post_status' do
    it 'successfully updates the post_status' do
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: stub_success_response,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_id: test_post_id,
        post_status: 'draft'
      )

      expect(result[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          expect(req.body).to include('status=draft')
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

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_id: test_post_id,
        visibility: :external,
        post_status: 'publish'
      )

      expect(result[:post_id]).to eq(test_post_id)

      expect(WebMock).to(
        have_requested(:post, api_url).with do |req|
          expect(req.body).to include('terms%5Bvisibility%5D=External')
          expect(req.body).to include('status=publish')
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
          body: { error: 'unauthorized', message: 'You are not authorized to access this resource.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_id: test_post_id,
          visibility: :external
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Update of Apps CDN build metadata failed')
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
          post_id: test_post_id,
          visibility: :external
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Update of Apps CDN build metadata failed')
    end
  end

  describe 'parameter validation' do
    it 'fails if site_id is empty' do
      expect do
        run_described_fastlane_action(
          site_id: '',
          api_token: test_api_token,
          post_id: test_post_id,
          visibility: :external
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Site ID cannot be empty')
    end

    it 'fails if api_token is empty' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: '',
          post_id: test_post_id,
          visibility: :external
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'API token cannot be empty')
    end

    it 'fails if post_id is not a positive integer' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_id: -1,
          visibility: :external
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Post ID must be a positive integer')
    end

    it 'fails if visibility is not a valid symbol' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_id: test_post_id,
          visibility: :public
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Visibility must be one of: `:internal`, `:external`')
    end

    it 'fails if post_status is not a valid value' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_id: test_post_id,
          post_status: 'invalid_status'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Post status must be one of: publish, draft')
    end

    it 'fails if no metadata to update is provided' do
      stub_request(:post, api_url) # Shouldn't be reached

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_id: test_post_id
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'No metadata to update. Provide at least one of: visibility, post_status')
    end
  end
end
