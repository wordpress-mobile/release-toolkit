require_relative './spec_helper'

describe Fastlane::Actions::UploadToS3Action do
  let(:client) { instance_double(Aws::S3::Client) }
  let(:test_bucket) { 'a8c-wpmrt-unit-tests-bucket' }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(client)
  end

  # Stub head_object to return a specific content_length
  def stub_s3_response_for_file(key, exists: true)
    content_length = exists == true ? 1 : 0
    allow(client).to(receive(:head_object))
                 .with(bucket: test_bucket, key: key)
                 .and_return(Aws::S3::Types::HeadObjectOutput.new(content_length: content_length))
  end

  describe 'uploading a file with valid parameters' do
    it 'generates a prefix for the key by default' do
      expected_key = '939c39398db2405e791e205778ff70f85dff620e/a8c-key1'
      stub_s3_response_for_file(expected_key, exists: false)

      with_tmp_file(named: 'input_file_1') do |file_path|
        expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

        return_value = run_described_fastlane_action(
          bucket: test_bucket,
          key: 'a8c-key1',
          file: file_path
        )

        expect(return_value).to eq(expected_key)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
      end
    end

    it 'generates a prefix for the key when using auto_prefix:true' do
      expected_key = '8bde1a7a04300df27b52f4383dc997e5fbbff180/a8c-key2'
      stub_s3_response_for_file(expected_key, exists: false)

      with_tmp_file(named: 'input_file_2') do |file_path|
        expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

        return_value = run_described_fastlane_action(
          bucket: test_bucket,
          key: 'a8c-key2',
          file: file_path,
          auto_prefix: true
        )

        expect(return_value).to eq(expected_key)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
      end
    end

    it 'uses the provided key verbatim when using auto_prefix:false' do
      expected_key = 'a8c-key1'
      stub_s3_response_for_file(expected_key, exists: false)

      with_tmp_file do |file_path|
        expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

        return_value = run_described_fastlane_action(
          bucket: test_bucket,
          key: 'a8c-key1',
          file: file_path,
          auto_prefix: false
        )

        expect(return_value).to eq(expected_key)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
      end
    end

    it 'correctly appends the key if it contains subdirectories' do
      expected_key = '939c39398db2405e791e205778ff70f85dff620e/subdir/a8c-key1'
      stub_s3_response_for_file(expected_key, exists: false)

      with_tmp_file(named: 'input_file_1') do |file_path|
        expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

        return_value = run_described_fastlane_action(
          bucket: test_bucket,
          key: 'subdir/a8c-key1',
          file: file_path
        )

        expect(return_value).to eq(expected_key)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
      end
    end

    it 'uses the filename as the key if one is not provided' do
      expected_key = 'c125bd799c6aad31092b02e440a8fae25b45a2ad/test_file_1'
      stub_s3_response_for_file(expected_key, exists: false)

      with_tmp_file(named: 'test_file_1') do |file_path|
        expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

        return_value = run_described_fastlane_action(
          bucket: test_bucket,
          file: file_path
        )

        expect(return_value).to eq(expected_key)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
      end
    end
  end

  describe 'uploading a file with invalid parameters' do
    it 'fails if bucket is empty or nil' do
      expect do
        with_tmp_file do |file_path|
          run_described_fastlane_action(
            bucket: '',
            key: 'key',
            file: file_path
          )
        end
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You must provide a valid bucket name')
    end

    it 'fails if an empty key is provided' do
      expect do
        with_tmp_file do |file_path|
          run_described_fastlane_action(
            bucket: test_bucket,
            key: '',
            file: file_path
          )
        end
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'The provided key must not be empty. Use nil instead if you want to default to the file basename')
    end

    it 'fails if local file does not exist' do
      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: 'key',
          file: 'this-file-does-not-exist.txt'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Path `this-file-does-not-exist.txt` does not exist.')
    end

    it 'fails if the file already exists on S3' do
      expected_key = 'a62f2225bf70bfaccbc7f1ef2a397836717377de/key'
      stub_s3_response_for_file(expected_key)

      with_tmp_file(named: 'key') do |file_path|
        expect do
          run_described_fastlane_action(
            bucket: test_bucket,
            key: 'key',
            file: file_path
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, "File already exists in S3 bucket #{test_bucket} at #{expected_key}")
      end
    end
  end
end
