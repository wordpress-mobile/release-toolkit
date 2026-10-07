# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Actions::DeleteFromS3Action do
  let(:client) { instance_double(Aws::S3::Client) }
  let(:test_bucket) { 'a8c-wpmrt-unit-tests-bucket' }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(client)
  end

  def stub_head_object(key, exists: true, last_modified: Time.now.utc)
    if exists
      allow(client).to(receive(:head_object))
                   .with(bucket: test_bucket, key: key)
                   .and_return(Aws::S3::Types::HeadObjectOutput.new(content_length: 1, last_modified: last_modified))
    else
      allow(client).to(receive(:head_object))
                   .with(bucket: test_bucket, key: key)
                   .and_raise(Aws::S3::Errors::NotFound.new(nil, 'Not Found'))
    end
  end

  def s3_object_stub(key:, last_modified:, size: 1024)
    instance_double(Aws::S3::Types::Object, key: key, last_modified: last_modified, size: size)
  end

  def list_response_stub(contents:, is_truncated: false, next_continuation_token: nil)
    instance_double(
      Aws::S3::Types::ListObjectsV2Output,
      contents: contents,
      is_truncated: is_truncated,
      next_continuation_token: next_continuation_token
    )
  end

  def delete_objects_response_stub(errors: [])
    instance_double(Aws::S3::Types::DeleteObjectsOutput, errors: errors)
  end

  describe 'single-key deletion' do
    it 'deletes the object from S3' do
      stub_head_object('my-key')
      expect(client).to receive(:delete_object).with(bucket: test_bucket, key: 'my-key')

      result = run_described_fastlane_action(
        bucket: test_bucket,
        key: 'my-key'
      )

      expect(result).to eq('my-key')
    end

    it 'fails by default when the file is not found' do
      stub_head_object('missing-key', exists: false)

      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: 'missing-key'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, "File not found in S3 bucket #{test_bucket} at missing-key")
    end

    it 'skips deletion when fail_if_not_found is false' do
      stub_head_object('missing-key', exists: false)

      warnings = []
      allow(FastlaneCore::UI).to receive(:important) { |message| warnings << message }

      expect(client).not_to receive(:delete_object)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        key: 'missing-key',
        fail_if_not_found: false
      )

      expect(result).to be_nil
      expect(warnings).to eq(["File not found in S3 bucket #{test_bucket} at missing-key. Skipping deletion."])
    end

    it 'returns the key after successful deletion' do
      stub_head_object('my-key')
      allow(client).to receive(:delete_object)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        key: 'my-key'
      )

      expect(result).to eq('my-key')
    end
  end

  describe 'single-key deletion with older_than_days' do
    it 'deletes an object older than the threshold' do
      old_time = Time.now.utc - (200 * 86_400)
      stub_head_object('my-key', last_modified: old_time)

      expect(client).to receive(:delete_object).with(bucket: test_bucket, key: 'my-key')

      result = run_described_fastlane_action(
        bucket: test_bucket,
        key: 'my-key',
        older_than_days: 180
      )

      expect(result).to eq('my-key')
    end

    it 'skips an object just inside the cutoff boundary' do
      # 179 days ago is within the 180-day window, so it should be skipped
      just_inside_cutoff = Time.now.utc - (179 * 86_400)
      stub_head_object('my-key', last_modified: just_inside_cutoff)

      expect(client).not_to receive(:delete_object)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        key: 'my-key',
        older_than_days: 180
      )

      expect(result).to be_nil
    end

    it 'skips an object newer than the threshold' do
      recent_time = Time.now.utc - (10 * 86_400)
      stub_head_object('my-key', last_modified: recent_time)

      expect(client).not_to receive(:delete_object)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        key: 'my-key',
        older_than_days: 180
      )

      expect(result).to be_nil
    end

    it 'logs what it would delete in dry_run mode' do
      old_time = Time.now.utc - (200 * 86_400)
      stub_head_object('my-key', last_modified: old_time)

      warnings = []
      allow(FastlaneCore::UI).to receive(:important) { |message| warnings << message }

      expect(client).not_to receive(:delete_object)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        key: 'my-key',
        older_than_days: 180,
        dry_run: true
      )

      expect(result).to eq('my-key')
      expect(warnings).to include('Dry run: would delete my-key')
    end
  end

  describe 'prefix-based deletion' do
    it 'deletes all objects matching the prefix' do
      now = Time.now.utc
      obj1 = s3_object_stub(key: 'trunk/build-1.zip', last_modified: now - (10 * 86_400))
      obj2 = s3_object_stub(key: 'trunk/build-2.zip', last_modified: now - (5 * 86_400))

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: [obj1, obj2]))

      allow(client).to receive(:delete_objects).with(
        bucket: test_bucket,
        delete: {
          objects: [{ key: 'trunk/build-1.zip' }, { key: 'trunk/build-2.zip' }],
          quiet: true
        }
      ).and_return(delete_objects_response_stub)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/'
      )

      expect(result).to contain_exactly('trunk/build-1.zip', 'trunk/build-2.zip')
    end

    it 'returns an empty array when no objects match' do
      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: []))

      expect(client).not_to receive(:delete_objects)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/'
      )

      expect(result).to eq([])
    end

    it 'handles pagination across multiple pages' do
      now = Time.now.utc
      obj1 = s3_object_stub(key: 'trunk/page1.zip', last_modified: now)
      obj2 = s3_object_stub(key: 'trunk/page2.zip', last_modified: now)

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: [obj1], is_truncated: true, next_continuation_token: 'token-1'))

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: 'token-1')
        .and_return(list_response_stub(contents: [obj2]))

      allow(client).to receive(:delete_objects).with(
        bucket: test_bucket,
        delete: {
          objects: [{ key: 'trunk/page1.zip' }, { key: 'trunk/page2.zip' }],
          quiet: true
        }
      ).and_return(delete_objects_response_stub)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/'
      )

      expect(result).to contain_exactly('trunk/page1.zip', 'trunk/page2.zip')
    end
  end

  describe 'prefix-based deletion with older_than_days' do
    it 'deletes only objects older than the threshold' do
      now = Time.now.utc
      old_obj = s3_object_stub(key: 'trunk/old-build.zip', last_modified: now - (200 * 86_400))
      new_obj = s3_object_stub(key: 'trunk/recent-build.zip', last_modified: now - (10 * 86_400))

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: [old_obj, new_obj]))

      allow(client).to receive(:delete_objects).with(
        bucket: test_bucket,
        delete: {
          objects: [{ key: 'trunk/old-build.zip' }],
          quiet: true
        }
      ).and_return(delete_objects_response_stub)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/',
        older_than_days: 180
      )

      expect(result).to eq(['trunk/old-build.zip'])
    end

    it 'logs skipped count when all objects are too recent' do
      now = Time.now.utc
      new_obj = s3_object_stub(key: 'trunk/recent-build.zip', last_modified: now - (10 * 86_400))

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: [new_obj]))

      messages = []
      allow(FastlaneCore::UI).to receive(:message) { |msg| messages << msg }

      expect(client).not_to receive(:delete_objects)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/',
        older_than_days: 180
      )

      expect(result).to eq([])
      expect(messages).to include("No objects eligible for deletion under prefix 'trunk/' (1 skipped as too recent)")
    end

    it 'does not delete in dry_run mode' do
      now = Time.now.utc
      old_obj = s3_object_stub(key: 'trunk/old-build.zip', last_modified: now - (200 * 86_400))

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: [old_obj]))

      expect(client).not_to receive(:delete_objects)

      result = run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/',
        older_than_days: 180,
        dry_run: true
      )

      expect(result).to eq(['trunk/old-build.zip'])
    end
  end

  describe 'batch deletion' do
    it 'splits into batches of 1000' do
      now = Time.now.utc
      objects = (1..1500).map { |i| s3_object_stub(key: "trunk/build-#{i}.zip", last_modified: now) }

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: objects))

      batch_sizes = []
      allow(client).to receive(:delete_objects) do |params|
        batch_sizes << params[:delete][:objects].length
        delete_objects_response_stub
      end

      run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/'
      )

      expect(batch_sizes).to eq([1000, 500])
    end
  end

  describe 'delete_objects error handling' do
    it 'raises when delete_objects returns errors' do
      now = Time.now.utc
      obj = s3_object_stub(key: 'trunk/build.zip', last_modified: now)

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: [obj]))

      error = instance_double(Aws::S3::Types::Error, key: 'trunk/build.zip', code: 'AccessDenied', message: 'Access Denied')
      allow(client).to receive(:delete_objects).and_return(delete_objects_response_stub(errors: [error]))

      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          prefix: 'trunk/'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, '1 object(s) failed to delete')
    end
  end

  describe 'S3 service error handling' do
    it 'crashes on S3 service error during single-key deletion' do
      stub_head_object('my-key')
      allow(client).to receive(:delete_object).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'Internal error'))

      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: 'my-key'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneCrash, /Unable to delete file from S3: Internal error/)
    end

    it 'crashes on non-NotFound S3 error during head_object' do
      allow(client).to(receive(:head_object))
                   .with(bucket: test_bucket, key: 'my-key')
                   .and_raise(Aws::S3::Errors::ServiceError.new(nil, 'Forbidden'))

      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: 'my-key'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneCrash, /Unable to delete file from S3: Forbidden/)
    end

    it 'crashes on S3 service error during prefix listing' do
      allow(client).to receive(:list_objects_v2).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'Access denied'))

      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          prefix: 'trunk/'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneCrash, /Unable to delete files from S3: Access denied/)
    end
  end

  describe 'silent mode' do
    it 'suppresses per-object log messages in single-key mode' do
      stub_head_object('my-key')
      expect(client).to receive(:delete_object).with(bucket: test_bucket, key: 'my-key')

      messages = []
      allow(FastlaneCore::UI).to receive(:message) { |msg| messages << msg }
      allow(FastlaneCore::UI).to receive(:success) { |msg| messages << msg }

      run_described_fastlane_action(
        bucket: test_bucket,
        key: 'my-key',
        silent: true
      )

      action_messages = messages.reject { |m| m.include?('Driving the lane') }
      expect(action_messages).to be_empty
    end

    it 'suppresses per-object log messages in prefix mode' do
      now = Time.now.utc
      obj = s3_object_stub(key: 'trunk/build.zip', last_modified: now)

      allow(client).to receive(:list_objects_v2)
        .with(bucket: test_bucket, prefix: 'trunk/', continuation_token: nil)
        .and_return(list_response_stub(contents: [obj]))
      allow(client).to receive(:delete_objects).and_return(delete_objects_response_stub)

      messages = []
      allow(FastlaneCore::UI).to receive(:message) { |msg| messages << msg }
      allow(FastlaneCore::UI).to receive(:success) { |msg| messages << msg }

      run_described_fastlane_action(
        bucket: test_bucket,
        prefix: 'trunk/',
        silent: true
      )

      action_messages = messages.reject { |m| m.include?('Driving the lane') }
      expect(action_messages).to be_empty
    end

    it 'suppresses not-found message when combined with fail_if_not_found: false' do
      stub_head_object('missing-key', exists: false)

      warnings = []
      allow(FastlaneCore::UI).to receive(:important) { |msg| warnings << msg }

      run_described_fastlane_action(
        bucket: test_bucket,
        key: 'missing-key',
        fail_if_not_found: false,
        silent: true
      )

      expect(warnings).to be_empty
    end

    it 'rejects dry_run and silent used together' do
      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: 'my-key',
          dry_run: true,
          silent: true
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You cannot use :dry_run and :silent at the same time')
    end
  end

  describe 'invalid parameters' do
    it 'fails if bucket is empty' do
      expect do
        run_described_fastlane_action(
          bucket: '',
          key: 'key'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You must provide a valid bucket name')
    end

    it 'fails if key is empty' do
      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: ''
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You must provide a valid key')
    end

    it 'fails if prefix is empty' do
      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          prefix: ''
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You must provide a valid prefix')
    end

    it 'fails if older_than_days is not positive' do
      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: 'key',
          older_than_days: 0
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'older_than_days must be a positive integer')
    end

    it 'fails if both key and prefix are provided' do
      expect do
        run_described_fastlane_action(
          bucket: test_bucket,
          key: 'my-key',
          prefix: 'trunk/'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Unresolved conflict between options/)
    end

    it 'fails if neither key nor prefix is provided' do
      expect do
        run_described_fastlane_action(
          bucket: test_bucket
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You must provide either :key or :prefix')
    end
  end
end
