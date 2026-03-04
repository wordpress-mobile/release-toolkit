# frozen_string_literal: true

require_relative 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::ListAppsCdnBuildsAction do
  let(:test_site_id) { '12345678' }
  let(:test_api_token) { 'test_api_token' }
  let(:v2_base) { "https://public-api.wordpress.com/wp/v2/sites/#{test_site_id}" }
  let(:api_url) { "#{v2_base}/a8c_cdn_build" }
  let(:version_term_url) { "#{v2_base}/version" }

  let(:version_term_id) { 42 }

  let(:sample_post) do
    {
      'id' => 100,
      'title' => { 'rendered' => 'WordPress.com Studio v1.7.5 Mac - Silicon' },
      'status' => 'publish',
      'class_list' => %w[version-v1-7-5 visibility-external platform-mac-silicon build_type-production]
    }
  end

  let(:sample_post_second) do
    {
      'id' => 101,
      'title' => { 'rendered' => 'WordPress.com Studio v1.7.5 Mac - Intel' },
      'status' => 'draft',
      'class_list' => %w[version-v1-7-5 visibility-external platform-mac-intel build_type-production]
    }
  end

  let(:sample_post_other_version) do
    {
      'id' => 200,
      'title' => { 'rendered' => 'WordPress.com Studio v1.7.4 Mac - Silicon' },
      'status' => 'publish',
      'class_list' => %w[version-v1-7-4 visibility-external platform-mac-silicon build_type-production]
    }
  end

  before do
    WebMock.disable_net_connect!
  end

  describe 'listing builds with no filters' do
    it 'returns all builds' do
      stub_request(:get, api_url)
        .with(query: { 'per_page' => '100' })
        .to_return(
          status: 200,
          body: [sample_post, sample_post_other_version].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token
      )

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)

      expect(result[0][:post_id]).to eq(100)
      expect(result[0][:title]).to eq('WordPress.com Studio v1.7.5 Mac - Silicon')
      expect(result[0][:status]).to eq('publish')
      expect(result[0][:version]).to eq('v1-7-5')
      expect(result[0][:visibility]).to eq('external')
      expect(result[0][:platform]).to eq('mac-silicon')
      expect(result[0][:build_type]).to eq('production')

      expect(result[1][:post_id]).to eq(200)

      expect(WebMock).to(
        have_requested(:get, api_url)
          .with(query: { 'per_page' => '100' }) do |req|
          expect(req.headers['Authorization']).to eq("Bearer #{test_api_token}")
          expect(req.headers['Accept']).to eq('application/json')
          true
        end
      )
    end
  end

  describe 'filtering by post_status' do
    it 'passes status as a server-side filter' do
      stub_request(:get, api_url)
        .with(query: { 'per_page' => '100', 'status' => 'draft' })
        .to_return(
          status: 200,
          body: [sample_post_second].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_status: 'draft'
      )

      expect(result.size).to eq(1)
      expect(result[0][:status]).to eq('draft')
    end
  end

  describe 'filtering by version (server-side via term lookup)' do
    it 'looks up the version term ID and filters server-side' do
      stub_request(:get, version_term_url)
        .with(query: { 'slug' => 'v1-7-5' })
        .to_return(
          status: 200,
          body: [{ 'id' => version_term_id, 'name' => 'v1.7.5', 'slug' => 'v1-7-5' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, api_url)
        .with(query: { 'per_page' => '100', 'version' => version_term_id.to_s })
        .to_return(
          status: 200,
          body: [sample_post, sample_post_second].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        version: 'v1.7.5'
      )

      expect(result.size).to eq(2)
      expect(result.map { |b| b[:post_id] }).to eq([100, 101])
    end

    it 'raises an error when the version term is not found' do
      stub_request(:get, version_term_url)
        .with(query: { 'slug' => 'v9-9-9' })
        .to_return(
          status: 200,
          body: [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          version: 'v9.9.9'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "No version term found for slug 'v9-9-9'")
    end

    it 'raises an error when the version term lookup fails' do
      stub_request(:get, version_term_url)
        .with(query: { 'slug' => 'v1-7-5' })
        .to_return(
          status: 500,
          body: 'Internal Server Error',
          headers: { 'Content-Type' => 'text/plain' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          version: 'v1.7.5'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Failed to look up version term 'v1-7-5': 500/)
    end
  end

  describe 'combining filters' do
    it 'filters by both post_status and version' do
      stub_request(:get, version_term_url)
        .with(query: { 'slug' => 'v1-7-5' })
        .to_return(
          status: 200,
          body: [{ 'id' => version_term_id, 'name' => 'v1.7.5', 'slug' => 'v1-7-5' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, api_url)
        .with(query: { 'per_page' => '100', 'status' => 'draft', 'version' => version_term_id.to_s })
        .to_return(
          status: 200,
          body: [sample_post_second].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        post_status: 'draft',
        version: 'v1.7.5'
      )

      expect(result.size).to eq(1)
      expect(result[0][:status]).to eq('draft')
    end
  end

  describe 'empty results' do
    it 'returns an empty array when no builds exist' do
      stub_request(:get, api_url)
        .with(query: { 'per_page' => '100' })
        .to_return(
          status: 200,
          body: [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token
      )

      expect(result).to be_an(Array)
      expect(result).to be_empty
    end
  end

  describe 'error handling' do
    it 'handles API authorization errors' do
      stub_request(:get, api_url)
        .with(query: { 'per_page' => '100' })
        .to_return(
          status: 403,
          body: { code: 'rest_forbidden', message: 'You are not authorized.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Listing of Apps CDN builds failed')
    end

    it 'handles server errors' do
      stub_request(:get, api_url)
        .with(query: { 'per_page' => '100' })
        .to_return(
          status: 500,
          body: 'Internal Server Error',
          headers: { 'Content-Type' => 'text/plain' }
        )

      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Listing of Apps CDN builds failed')
    end
  end

  describe 'parameter validation' do
    it 'fails if site_id is empty' do
      expect do
        run_described_fastlane_action(
          site_id: '',
          api_token: test_api_token
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Site ID cannot be empty')
    end

    it 'fails if api_token is empty' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: ''
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'API token cannot be empty')
    end

    it 'fails if post_status is not valid' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          post_status: 'pending'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Post status must be one of: publish, draft')
    end
  end
end
