# frozen_string_literal: true

require_relative 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::ListAppsCdnBuildsAction do
  let(:test_site_id) { '12345678' }
  let(:test_api_token) { 'test_api_token' }
  let(:api_url) { "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/posts" }

  let(:sample_post) do
    {
      'ID' => 100,
      'title' => 'WordPress.com Studio v1.7.5 Mac - Silicon',
      'terms' => {
        'version' => { 'v1.7.5' => { 'ID' => 10, 'name' => 'v1.7.5', 'slug' => 'v1-7-5' } },
        'visibility' => { 'Internal' => { 'ID' => 20, 'name' => 'Internal', 'slug' => 'internal' } },
        'platform' => { 'Mac - Silicon' => { 'ID' => 30, 'name' => 'Mac - Silicon', 'slug' => 'mac-silicon' } },
        'build_type' => { 'Production' => { 'ID' => 40, 'name' => 'Production', 'slug' => 'production' } }
      }
    }
  end

  let(:sample_post_second) do
    {
      'ID' => 101,
      'title' => 'WordPress.com Studio v1.7.5 Mac - Intel',
      'terms' => {
        'version' => { 'v1.7.5' => { 'ID' => 10, 'name' => 'v1.7.5', 'slug' => 'v1-7-5' } },
        'visibility' => { 'Internal' => { 'ID' => 20, 'name' => 'Internal', 'slug' => 'internal' } },
        'platform' => { 'Mac - Intel' => { 'ID' => 31, 'name' => 'Mac - Intel', 'slug' => 'mac-intel' } },
        'build_type' => { 'Production' => { 'ID' => 40, 'name' => 'Production', 'slug' => 'production' } }
      }
    }
  end

  let(:sample_post_other_version) do
    {
      'ID' => 200,
      'title' => 'WordPress.com Studio v1.7.4 Mac - Silicon',
      'terms' => {
        'version' => { 'v1.7.4' => { 'ID' => 11, 'name' => 'v1.7.4', 'slug' => 'v1-7-4' } },
        'visibility' => { 'External' => { 'ID' => 21, 'name' => 'External', 'slug' => 'external' } },
        'platform' => { 'Mac - Silicon' => { 'ID' => 30, 'name' => 'Mac - Silicon', 'slug' => 'mac-silicon' } },
        'build_type' => { 'Production' => { 'ID' => 40, 'name' => 'Production', 'slug' => 'production' } }
      }
    }
  end

  before do
    WebMock.disable_net_connect!
  end

  describe 'listing builds with no filters' do
    it 'returns all builds' do
      stub_request(:get, api_url)
        .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100' })
        .to_return(
          status: 200,
          body: { 'posts' => [sample_post, sample_post_other_version] }.to_json,
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
      expect(result[0][:version]).to eq('v1.7.5')
      expect(result[0][:visibility]).to eq('internal')
      expect(result[0][:platform]).to eq('Mac - Silicon')
      expect(result[0][:build_type]).to eq('Production')

      expect(result[1][:post_id]).to eq(200)

      expect(WebMock).to(
        have_requested(:get, api_url)
          .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100' }) do |req|
          expect(req.headers['Authorization']).to eq("Bearer #{test_api_token}")
          expect(req.headers['Accept']).to eq('application/json')
          true
        end
      )
    end
  end

  describe 'filtering by visibility (server-side)' do
    it 'passes visibility as a server-side filter' do
      stub_request(:get, api_url)
        .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100', 'term[visibility]' => 'Internal' })
        .to_return(
          status: 200,
          body: { 'posts' => [sample_post] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        visibility: :internal
      )

      expect(result.size).to eq(1)
      expect(result[0][:visibility]).to eq('internal')
    end
  end

  describe 'filtering by version (client-side)' do
    it 'filters builds by matching version taxonomy keys' do
      stub_request(:get, api_url)
        .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100' })
        .to_return(
          status: 200,
          body: { 'posts' => [sample_post, sample_post_second, sample_post_other_version] }.to_json,
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

    it 'returns empty array when no builds match the version' do
      stub_request(:get, api_url)
        .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100' })
        .to_return(
          status: 200,
          body: { 'posts' => [sample_post] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = run_described_fastlane_action(
        site_id: test_site_id,
        api_token: test_api_token,
        version: 'v9.9.9'
      )

      expect(result).to be_empty
    end
  end

  describe 'empty results' do
    it 'returns an empty array when no builds exist' do
      stub_request(:get, api_url)
        .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100' })
        .to_return(
          status: 200,
          body: { 'posts' => [] }.to_json,
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
        .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100' })
        .to_return(
          status: 403,
          body: { error: 'unauthorized', message: 'You are not authorized to access this resource.' }.to_json,
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
        .with(query: { 'type' => 'a8c_cdn_build', 'number' => '100' })
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

    it 'fails if visibility is not a valid symbol' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          visibility: :public
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Visibility must be one of: `:internal`, `:external`')
    end
  end
end
