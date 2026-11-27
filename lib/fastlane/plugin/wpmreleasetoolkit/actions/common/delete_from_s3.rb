# frozen_string_literal: true

require 'fastlane/action'

module Fastlane
  module Actions
    class DeleteFromS3Action < Action
      def self.run(params)
        bucket = params[:bucket]
        key = params[:key]
        prefix = params[:prefix]
        older_than_days = params[:older_than_days]
        dry_run = params[:dry_run]
        silent = params[:silent]

        UI.user_error!('You must provide either :key or :prefix') if key.nil? && prefix.nil?
        UI.user_error!('You cannot use :dry_run and :silent at the same time') if dry_run && silent

        if prefix
          delete_by_prefix(bucket: bucket, prefix: prefix, older_than_days: older_than_days, dry_run: dry_run, silent: silent)
        else
          delete_by_key(bucket: bucket, key: key, older_than_days: older_than_days, dry_run: dry_run, silent: silent, fail_if_not_found: params[:fail_if_not_found])
        end
      end

      def self.delete_by_key(bucket:, key:, older_than_days:, dry_run:, silent:, fail_if_not_found:)
        client = Aws::S3::Client.new
        metadata = head_object(client: client, bucket: bucket, key: key)

        if metadata.nil?
          if fail_if_not_found
            UI.user_error!("File not found in S3 bucket #{bucket} at #{key}")
          else
            UI.important("File not found in S3 bucket #{bucket} at #{key}. Skipping deletion.") unless silent
            return nil
          end
        end

        if older_than_days
          last_modified = metadata[:last_modified]
          cutoff = Time.now.utc - (older_than_days * 86_400)

          if last_modified >= cutoff
            UI.message("Skipping #{key} - last modified #{last_modified.iso8601}, not older than #{older_than_days} days") unless silent
            return nil
          end

          UI.message("#{key} last modified #{last_modified.iso8601}, older than #{older_than_days} days") unless silent
        end

        if dry_run
          UI.important("Dry run: would delete #{key}") unless silent
          return key
        end

        UI.message("Deleting #{key} from S3 bucket #{bucket}") unless silent

        client.delete_object(bucket: bucket, key: key)

        UI.success('Deletion complete') unless silent
        key
      rescue Aws::S3::Errors::ServiceError => e
        UI.crash!("Unable to delete file from S3: #{e.message}")
      end

      def self.delete_by_prefix(bucket:, prefix:, older_than_days:, dry_run:, silent:)
        client = Aws::S3::Client.new
        cutoff = older_than_days ? Time.now.utc - (older_than_days * 86_400) : nil

        UI.message("Listing objects in s3://#{bucket}/#{prefix}...") unless silent

        to_delete = []
        skipped = 0
        continuation_token = nil

        loop do
          response = client.list_objects_v2(
            bucket: bucket,
            prefix: prefix,
            continuation_token: continuation_token
          )

          response.contents.each do |object|
            if cutoff && object.last_modified >= cutoff
              UI.message("Skipping #{object.key} - last modified #{object.last_modified.iso8601}, not older than #{older_than_days} days") unless silent
              skipped += 1
              next
            end

            UI.message("Will delete #{object.key} (last modified #{object.last_modified.iso8601})") unless silent
            to_delete << object.key
          end

          break unless response.is_truncated

          continuation_token = response.next_continuation_token
        end

        if to_delete.empty?
          message = if skipped.positive?
                      "No objects eligible for deletion under prefix '#{prefix}' (#{skipped} skipped as too recent)"
                    else
                      "No objects found under prefix '#{prefix}'"
                    end
          UI.message(message) unless silent
          return []
        end

        if dry_run
          UI.important("Dry run: would delete #{to_delete.length} object(s), skipped #{skipped}") unless silent
          return to_delete
        end

        UI.message("Deleting #{to_delete.length} object(s)...") unless silent
        delete_objects_in_batches(client: client, bucket: bucket, keys: to_delete, silent: silent)
        UI.success("Deleted #{to_delete.length} object(s) from s3://#{bucket}/#{prefix} (skipped #{skipped})") unless silent

        to_delete
      rescue Aws::S3::Errors::ServiceError => e
        UI.crash!("Unable to delete files from S3: #{e.message}")
      end

      def self.delete_objects_in_batches(client:, bucket:, keys:, silent: false)
        keys.each_slice(1000) do |batch|
          response = client.delete_objects(
            bucket: bucket,
            delete: {
              objects: batch.map { |key| { key: key } },
              quiet: true
            }
          )

          next if response.errors.nil? || response.errors.empty?

          response.errors.each do |error|
            UI.error("Failed to delete #{error.key}: #{error.code} - #{error.message}") unless silent
          end
          failed_keys = response.errors.map(&:key)
          succeeded = batch.reject { |key| failed_keys.include?(key) }
          UI.message("#{succeeded.length} object(s) in this batch were deleted successfully") unless succeeded.empty? || silent
          UI.user_error!("#{response.errors.length} object(s) failed to delete")
        end
      end

      # Returns the head_object response hash, or nil if the object does not exist.
      def self.head_object(client:, bucket:, key:)
        client.head_object(bucket: bucket, key: key)
      rescue Aws::S3::Errors::NotFound
        nil
      end

      def self.description
        'Deletes files from S3'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The deleted key or nil (single-key mode), or an array of deleted keys (prefix mode, empty array if none matched). ' \
          'In dry-run mode, returns what would have been deleted.'
      end

      def self.details
        <<~DETAILS
          Deletes objects from an S3 bucket, either by exact key or by key prefix.

          In single-key mode (:key), deletes one object. In prefix mode (:prefix),
          lists all matching objects and batch-deletes them. Both modes support
          :older_than_days to only delete objects older than a given number of days.

          Use :dry_run to preview what would be deleted without making changes.
          Use :silent to suppress per-object log output.
        DETAILS
      end

      def self.example_code
        [
          '# Delete a single object
          delete_from_s3(bucket: "my-bucket", key: "path/to/file.zip")',
          '# Delete a single object only if older than 90 days
          delete_from_s3(bucket: "my-bucket", key: "path/to/file.zip", older_than_days: 90)',
          '# Delete all objects under a prefix older than 180 days
          delete_from_s3(bucket: "my-bucket", prefix: "trunk/", older_than_days: 180)',
          '# Dry run: see what would be deleted without deleting
          delete_from_s3(bucket: "my-bucket", prefix: "trunk/", older_than_days: 180, dry_run: true)',
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :bucket,
            description: 'The bucket containing the file(s) to delete',
            optional: false,
            type: String,
            verify_block: proc { |bucket| UI.user_error!('You must provide a valid bucket name') if bucket.empty? }
          ),
          FastlaneCore::ConfigItem.new(
            key: :key,
            description: 'The exact key of the object to delete. Mutually exclusive with :prefix',
            optional: true,
            conflicting_options: [:prefix],
            type: String,
            verify_block: proc { |key|
              next if key.is_a?(String) && !key.empty?

              UI.user_error!('You must provide a valid key')
            }
          ),
          FastlaneCore::ConfigItem.new(
            key: :prefix,
            description: 'A key prefix - all matching objects will be deleted. Mutually exclusive with :key',
            optional: true,
            conflicting_options: [:key],
            type: String,
            verify_block: proc { |prefix|
              next if prefix.is_a?(String) && !prefix.empty?

              UI.user_error!('You must provide a valid prefix')
            }
          ),
          FastlaneCore::ConfigItem.new(
            key: :older_than_days,
            description: 'Only delete objects whose last_modified is older than this many days',
            optional: true,
            type: Integer,
            verify_block: proc { |days| UI.user_error!('older_than_days must be a positive integer') unless days.positive? }
          ),
          FastlaneCore::ConfigItem.new(
            key: :dry_run,
            description: 'When true, log what would be deleted without actually deleting',
            optional: true,
            default_value: false,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :silent,
            description: 'When true, suppress per-object log messages',
            optional: true,
            default_value: false,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :fail_if_not_found,
            description: 'Whether to fail with `user_error!` if the file does not exist (single-key mode only)',
            optional: true,
            default_value: true,
            type: Boolean
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
