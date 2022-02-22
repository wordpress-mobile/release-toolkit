require 'tempfile'
require_relative './spec_helper'

describe Fastlane::Actions::UploadToS3Action do
  let(:client) { instance_double(Aws::S3::Client) }
  let(:test_bucket) { 'a8c-wpmrt-unit-tests-bucket' }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(client)
  end

  # Stub head_object to return a specific content_length
  def stub_s3_head_request(key, content_length)
    allow(client).to receive(:head_object)
      .with(bucket: test_bucket, key: key)
      .and_return(Aws::S3::Types::HeadObjectOutput.new(content_length: content_length))
  end

  # Allow us to do `.with` matching against a `File` instance to a particular path in RSpec expectations
  # Because `File.open(path)` returns a different instance of `File` for the same path on each call)
  RSpec::Matchers.define :file_instance_of do |path|
    match { |actual| actual.is_a?(File) && actual.path == path }
  end

  describe 'happy path' do
    it 'generates a prefix for the key by default' do
      in_tmp_dir do |tmp_dir|
        file_path = File.join(tmp_dir, 'input_file_1')
        File.write(file_path, 'Dummy content')
        expected_key = 'k5w5OY2yQF55HiBXeP9w+F3/Yg4=/subdir/a8c-key1'

        stub_s3_head_request(expected_key, 0) # File does not exist in S3
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

    it 'generates a prefix for the key when using auto_prefix:true' do
      in_tmp_dir do |tmp_dir|
        file_path = File.join(tmp_dir, 'input_file_2')
        File.write(file_path, 'Dummy content')
        expected_key = 'i94aegQwDfJ7UvQ4PcmX5fu/8YA=/subdir/a8c-key2'

        stub_s3_head_request(expected_key, 0) # File does not exist in S3
        expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

        return_value = run_described_fastlane_action(
          bucket: test_bucket,
          key: 'subdir/a8c-key2',
          file: file_path,
          auto_prefix: true
        )

        expect(return_value).to eq(expected_key)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
      end
    end

    it 'uses the provided key verbatim when using auto_prefix:false' do
      in_tmp_dir do |tmp_dir|
        file_path = File.join(tmp_dir, 'input_file_1')
        File.write(file_path, 'Dummy content')
        expected_key = 'subdir/a8c-key1'

        stub_s3_head_request(expected_key, 0) # File does not exist in S3
        expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

        return_value = run_described_fastlane_action(
          bucket: test_bucket,
          key: 'subdir/a8c-key1',
          file: file_path,
          auto_prefix: false
        )

        expect(return_value).to eq(expected_key)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
      end
    end
  end

  describe 'error reporting' do
    it 'errors if bucket is empty or nil'
    it 'errors if key is nil' # Or should it auto-generate a key based on the filename or something instead in that case?
    it 'errors if local file to upload does not exist'
    it 'reports an error if the file already exists on S3'
  end
end
