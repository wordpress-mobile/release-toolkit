# frozen_string_literal: true

require_relative 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Actions::UploadBuildToAppsCdnAction do
  let(:test_site_id) { '12345678' }
  let(:test_api_token) { 'test_api_token' }
  let(:test_product) { 'WordPress.com Studio' }
  let(:test_build_type) { 'Beta' }
  let(:test_visibility) { :internal }
  let(:test_platform) { 'Mac - Any' }
  let(:test_version) { '20.0' }
  let(:test_build_number) { '42' }
  let(:test_media_id) { '987654' }
  let(:test_media_url) { 'https://example.com/uploads/app.zip' }
  let(:test_post_id) { '12345' }
  let(:test_post_url) { 'https://example.com/?p=12345' }

  before do
    WebMock.disable_net_connect!
  end

  after do
    WebMock.allow_net_connect!
  end

  # Helper method to build the expected multipart form data part
  def expected_form_part(boundary:, name:, value:, filename: nil)
    lines = ["--#{boundary}"]
    if filename
      lines << "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\""
      lines << 'Content-Type: application/octet-stream'
    else
      lines << "Content-Disposition: form-data; name=\"#{name}\""
    end

    lines << ''
    lines << value
    lines.join("\r\n")
  end

  describe 'uploading a build with valid parameters' do
    it 'successfully uploads the build and returns the media details' do
      with_tmp_file(named: 'test_app.zip', content: 'test app binary') do |file_path|
        # Stub the WordPress.com API request
        stub_request(:post, "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/media/new")
          .to_return(
            status: 200,
            body: {
              media: [
                {
                  ID: test_media_id,
                  URL: test_media_url,
                  date: '2023-06-15T12:00:00Z',
                  mime_type: 'application/zip',
                  file: 'test_app.zip',
                  post_ID: test_post_id
                },
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Run the action
        result = run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          product: test_product,
          build_type: test_build_type,
          visibility: test_visibility,
          platform: test_platform,
          version: test_version,
          build_number: test_build_number,
          file_path: file_path
        )

        # Verify the result
        expect(result).to be_a(Hash)
        expect(result[:post_id]).to eq(test_post_id)
        expect(result[:post_url]).to eq(test_post_url)
        expect(result[:media_id]).to eq(test_media_id)
        expect(result[:media_url]).to eq(test_media_url)
        expect(result[:mime_type]).to eq('application/zip')

        # Verify the shared values
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPS_CDN_UPLOADED_FILE_URL]).to eq(test_media_url)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPS_CDN_UPLOADED_FILE_ID]).to eq(test_media_id)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPS_CDN_UPLOADED_POST_ID]).to eq(test_post_id)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APPS_CDN_UPLOADED_POST_URL]).to eq(test_post_url)

        # Verify that the request was made with the correct parameters
        expect(WebMock).to(
          have_requested(:post, "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/media/new").with do |req|
            # Check that the request contains the expected headers
            expect(req.headers['Content-Type']).to include('multipart/form-data')
            expect(req.headers['Authorization']).to eq("Bearer #{test_api_token}")

            boundary = req.headers['Content-Type'].match(/boundary=([^;]+)/)[1]

            # Verify the media file is included with proper attributes
            expect(req.body).to include(expected_form_part(boundary: boundary, name: 'media[]', value: 'test app binary', filename: 'test_app.zip'))

            # Verify each parameter has the correct value
            {
              'product' => test_product,
              'build_type' => test_build_type,
              'visibility' => 'Internal', # Capitalized from :internal
              'platform' => test_platform,
              'resource_type' => 'Build', # RESOURCE_TYPE constant
              'version' => test_version,
              'build_number' => test_build_number
            }.each do |name, value|
              expect(req.body).to include(expected_form_part(boundary: boundary, name: name, value: value))
            end

            true
          end
        )
      end
    end

    it 'successfully uploads the build with more optional parameters' do
      with_tmp_file(named: 'test_app.zip', content: 'test app binary') do |file_path|
        # Stub the WordPress.com API request
        stub_request(:post, "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/media/new")
          .to_return(
            status: 200,
            body: {
              media: [
                {
                  ID: test_media_id,
                  URL: test_media_url,
                  date: '2023-06-15T12:00:00Z',
                  mime_type: 'application/zip',
                  file: 'test_app.zip',
                  post_ID: test_post_id
                },
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Run the action with external visibility and error_on_duplicate
        result = run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          product: test_product,
          build_type: test_build_type,
          visibility: :external,
          platform: test_platform,
          version: test_version,
          build_number: test_build_number,
          file_path: file_path,
          error_on_duplicate: true
        )

        # Verify the result
        expect(result).to be_a(Hash)
        expect(result[:post_id]).to eq(test_post_id)
        expect(result[:post_url]).to eq(test_post_url)
        expect(result[:media_id]).to eq(test_media_id)
        expect(result[:media_url]).to eq(test_media_url)
        expect(result[:mime_type]).to eq('application/zip')

        # Verify that the request was made with the correct parameters
        expect(WebMock).to(
          have_requested(:post, "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/media/new").with do |req|
            boundary = req.headers['Content-Type'].match(/boundary=([^;]+)/)[1]

            # Check that the visibility is set to External
            expect(req.body).to include(expected_form_part(boundary: boundary, name: 'visibility', value: 'External'))
            true
          end
        )
      end
    end

    it 'handles API validation errors properly' do
      with_tmp_file(named: 'test_app.zip', content: 'test app binary') do |file_path|
        # Stub the WordPress.com API request to return a validation error
        stub_request(:post, "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/media/new")
          .to_return(
            status: 400,
            body: {
              errors: [
                {
                  file: 'test.txt',
                  error: 'validation_error',
                  message: 'A build with this data already exists, and you configured this request to error if a duplicate is found.'
                },
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Run the action and expect it to raise an error
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            build_number: test_build_number,
            file_path: file_path,
            error_on_duplicate: true
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Upload to apps CDN failed')
      end
    end

    it 'handles non-JSON API errors properly' do
      with_tmp_file(named: 'test_app.zip', content: 'test app binary') do |file_path|
        # Stub the WordPress.com API request to return a non-JSON error
        stub_request(:post, "https://public-api.wordpress.com/rest/v1.1/sites/#{test_site_id}/media/new")
          .to_return(
            status: 500,
            body: 'Internal Server Error',
            headers: { 'Content-Type' => 'text/plain' }
          )

        # Run the action and expect it to raise an error
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            build_number: test_build_number,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Upload to apps CDN failed')
      end
    end
  end

  describe 'parameter validation' do
    it 'fails if site_id is empty' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: '',
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Site ID cannot be empty')
      end
    end

    it 'fails if api_token is empty' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: '',
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'API token cannot be empty')
      end
    end

    it 'fails if product is empty' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: '',
            build_type: test_build_type,
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Product cannot be empty')
      end
    end

    it 'fails if build_type is empty' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: '',
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Build type cannot be empty')
      end
    end

    it 'fails if build_type is not a valid value' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: 'InvalidType',
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Build type must be one of: Alpha, Beta, Nightly, Production, Prototype')
      end
    end

    it 'fails if visibility is not a valid symbol' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: :public, # Invalid value
            platform: test_platform,
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Visibility must be either :internal or :external')
      end
    end

    it 'fails if platform is empty' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: '',
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Platform cannot be empty')
      end
    end

    it 'fails if platform is not a valid value' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: 'InvalidPlatform',
            version: test_version,
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Platform must be one of: Android, iOS, Mac - Silicon, Mac - Intel, Mac - Any, Windows')
      end
    end

    it 'fails if version is empty' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: test_platform,
            version: '',
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Version cannot be empty')
      end
    end

    it 'fails if post_status is not a valid value' do
      with_tmp_file(named: 'test_app.zip') do |file_path|
        expect do
          run_described_fastlane_action(
            site_id: test_site_id,
            api_token: test_api_token,
            product: test_product,
            build_type: test_build_type,
            visibility: test_visibility,
            platform: test_platform,
            version: test_version,
            post_status: 'invalid_status',
            file_path: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Post status must be one of: publish, draft')
      end
    end

    it 'fails if the file does not exist' do
      expect do
        run_described_fastlane_action(
          site_id: test_site_id,
          api_token: test_api_token,
          product: test_product,
          build_type: test_build_type,
          visibility: test_visibility,
          platform: test_platform,
          version: test_version,
          file_path: 'non_existent_file.zip'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "File not found at path 'non_existent_file.zip'")
    end
  end
end
