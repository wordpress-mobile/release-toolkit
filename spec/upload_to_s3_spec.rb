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

    context 'when the file already exists on S3' do
      it 'fails if skip_if_exists and if_exists are both unspecified (default behavior)' do
        expected_key = '29d5f92e9ee44d4854d6dfaeefc3dc27d779fdf3/existing-key'
        stub_s3_response_for_file(expected_key)

        with_tmp_file(named: 'existing-key') do |file_path|
          expect do
            run_described_fastlane_action(
              bucket: test_bucket,
              key: 'existing-key',
              file: file_path
            )
          end.to raise_error(FastlaneCore::Interface::FastlaneError, "File already exists in S3 bucket #{test_bucket} at #{expected_key}")
        end
      end

      context 'when if_exists is unspecified' do
        it 'logs a message if skip_if_exist:true' do
          expected_key = '29d5f92e9ee44d4854d6dfaeefc3dc27d779fdf3/existing-key'
          stub_s3_response_for_file(expected_key)

          warnings = []
          allow(FastlaneCore::UI).to receive(:important) { |message| warnings << message }

          with_tmp_file(named: 'existing-key') do |file_path|
            key = run_described_fastlane_action(
              bucket: test_bucket,
              key: 'existing-key',
              file: file_path,
              skip_if_exists: true
            )

            expect(warnings).to eq(["File already exists in S3 bucket #{test_bucket} at #{expected_key}. Skipping upload."])
            expect(key).to eq(expected_key)
          end
        end

        it 'fails if skip_if_exists:false' do
          expected_key = 'faf2b3798ee00168b43fc303d160e0a068e72a7c/existing-key-2'
          stub_s3_response_for_file(expected_key)

          with_tmp_file(named: 'existing-key-2') do |file_path|
            expect do
              run_described_fastlane_action(
                bucket: test_bucket,
                key: 'existing-key-2',
                file: file_path,
                skip_if_exists: false
              )
            end.to raise_error(FastlaneCore::Interface::FastlaneError, "File already exists in S3 bucket #{test_bucket} at #{expected_key}")
          end
        end
      end

      context 'when if_exists is explicitly set' do
        it 'fails when if_exist is :fail' do
          expected_key = '29d5f92e9ee44d4854d6dfaeefc3dc27d779fdf3/existing-key'
          stub_s3_response_for_file(expected_key)

          with_tmp_file(named: 'existing-key') do |file_path|
            expect do
              run_described_fastlane_action(
                bucket: test_bucket,
                key: 'existing-key',
                file: file_path,
                if_exists: :fail
              )
            end.to raise_error(FastlaneCore::Interface::FastlaneError, "File already exists in S3 bucket #{test_bucket} at #{expected_key}")
          end
        end

        it 'logs a message without failing when if_exists is :skip' do
          expected_key = '29d5f92e9ee44d4854d6dfaeefc3dc27d779fdf3/existing-key'
          stub_s3_response_for_file(expected_key)

          warnings = []
          allow(FastlaneCore::UI).to receive(:important) { |message| warnings << message }

          with_tmp_file(named: 'existing-key') do |file_path|
            key = run_described_fastlane_action(
              bucket: test_bucket,
              key: 'existing-key',
              file: file_path,
              if_exists: :skip
            )

            expect(warnings).to eq(["File already exists in S3 bucket #{test_bucket} at #{expected_key}. Skipping upload."])
            expect(key).to eq(expected_key)
          end
        end

        it 'upload the file overriding the existing one when if_exists is :replace' do
          expected_key = '29d5f92e9ee44d4854d6dfaeefc3dc27d779fdf3/existing-key'
          stub_s3_response_for_file(expected_key)

          warnings = []
          allow(FastlaneCore::UI).to receive(:important) { |message| warnings << message }

          with_tmp_file(named: 'existing-key') do |file_path|
            expect(client).to receive(:put_object).with(body: file_instance_of(file_path), bucket: test_bucket, key: expected_key)

            return_value = run_described_fastlane_action(
              bucket: test_bucket,
              key: 'existing-key',
              file: file_path,
              if_exists: :replace
            )

            expect(return_value).to eq(expected_key)
            expect(warnings).to include("File already exists in S3 bucket #{test_bucket} at #{expected_key}. Will replace with the given one.")
            expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::S3_UPLOADED_FILE_PATH]).to eq(expected_key)
          end
        end

        it 'throws when if_exists is not one of the expected values' do
          with_tmp_file(named: 'key') do |file_path|
            expect do
              run_described_fastlane_action(
                bucket: test_bucket,
                key: 'a8c-key1',
                file: file_path,
                if_exists: :invalid
              )
            end.to raise_error(FastlaneCore::Interface::FastlaneError, '`if_exist` must be one of :skip, :replace, :fail')
          end
        end

        # Untill we remove the deprecated skip_if_exists option, if_exists needs to be optional.
        # if_exists also has a verify_block that will throw if the given value doesn't match the allowed ones.
        # This test makes sure that if the user omits or set if_exists as nil, Fastlane bypasses the verify_block.
        # This is models a possible usage for the action—we want to be extra careful.
        #
        # See also https://github.com/wordpress-mobile/release-toolkit/pull/500#discussion_r1239644683
        it 'does not fail the verify_block if if_exists is explicitly nil' do
          expected_key = '29d5f92e9ee44d4854d6dfaeefc3dc27d779fdf3/existing-key'
          stub_s3_response_for_file(expected_key, exists: true)

          with_tmp_file(named: 'existing-key') do |file_path|
            expect do
              run_described_fastlane_action(
                bucket: test_bucket,
                key: 'existing-key',
                file: file_path,
                if_exists: nil
              )
            end.to raise_error(
              # If the verify_block doesn't fail, then we should expect the action to behave as per its default.
              # In the context of the file already existing, the default behavior is to fail.
              FastlaneCore::Interface::FastlaneError, "File already exists in S3 bucket #{test_bucket} at #{expected_key}"
            )
          end
        end
      end
    end

    # test all combinations of skip_if_exists and if_exists
    [true, false].product(%i[skip fail replace]).each do |skip_if_exists, if_exists|
      it "does not allow to have both skip_if_exists and if_exists set at the same time (#{skip_if_exists}, #{if_exists})" do
        with_tmp_file(named: 'existing-key') do |file_path|
          expect do
            run_described_fastlane_action(
              bucket: test_bucket,
              key: 'existing-key',
              file: file_path,
              if_exists: if_exists,
              skip_if_exists: skip_if_exists
            )
          end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You cannot set both :skip_if_exists and :if_exists. Please only use :if_exists.')
        end
      end
    end
  end
end
