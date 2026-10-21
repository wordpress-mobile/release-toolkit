# frozen_string_literal: true

require 'fastlane/action'
require_relative '../../helper/macos/sparkle_helper'

module Fastlane
  module Actions
    class MacosSignUpdateAction < Action
      def self.run(params)
        Helper::SparkleHelper.sign_update(
          archive_path: params[:archive_path],
          signing_tool: params[:signing_tool],
          private_key: params[:private_key],
          public_key: params[:public_key]
        )
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :archive_path,
            description: 'The final update archive to sign, after code signing, notarizing and stapling',
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Archive not found at '#{value}'") unless File.file?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :signing_tool,
            description: 'The sign_update executable from the app\'s resolved Sparkle release',
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Sparkle signing tool is not executable at '#{value}'") unless File.file?(value) && File.executable?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :public_key,
            description: 'The SUPublicEDKey value embedded in the app being released',
            type: String,
            verify_block: proc do |value|
              Helper::SparkleHelper.validate_public_key!(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :private_key,
            env_name: 'SPARKLE_PRIVATE_KEY',
            description: 'The exported Sparkle private key (required)',
            type: String,
            sensitive: true,
            # Validate inside the helper: ConfigItem logs invalid values even when marked sensitive.
            # Optional here also avoids prompting for a missing key in unattended release jobs.
            optional: true
          ),
        ]
      end

      def self.description
        'Sign a macOS update archive with Sparkle EdDSA'
      end

      def self.details
        'Pass the sign_update executable from the same Sparkle release used by the app. The private key is sent through standard input and the signature is verified against the app public key. Upload the archive without modifying it after signing.'
      end

      def self.return_value
        'A Hash containing :ed_signature and :length (archive size in bytes)'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :mac
      end

      def self.example_code
        [
          'signature = macos_sign_update(
            archive_path: "build/App.zip",
            signing_tool: "build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update",
            public_key: get_info_plist_value(path: "App/Info.plist", key: "SUPublicEDKey")
          )
          # Pass signature[:ed_signature] as ed_signature to upload_build_to_apps_cdn.',
        ]
      end
    end
  end
end
