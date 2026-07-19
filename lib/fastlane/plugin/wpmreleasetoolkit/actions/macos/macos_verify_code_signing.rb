# frozen_string_literal: true

module Fastlane
  module Actions
    class MacosVerifyCodeSigningAction < Action
      def self.run(params)
        app_paths = Array(params[:app_path])
        UI.user_error!('No app bundle to verify: `app_path` is empty') if app_paths.empty?

        app_paths.each do |app_path|
          UI.user_error!("There is no app bundle at #{app_path}") unless File.exist?(app_path)

          UI.message("Verifying code signing of #{app_path}")

          verify!("The code signature of #{app_path} is not valid", 'codesign', '--verify', '--deep', '--strict', '--verbose=2', app_path)
          verify_authority!(app_path: app_path, expected_authority: params[:expected_authority]) unless params[:expected_authority].nil?

          next unless params[:verify_notarization]

          verify!("#{app_path} was rejected by Gatekeeper", 'spctl', '--assess', '--type', 'execute', '--verbose=2', app_path)
          verify!("#{app_path} has no notarization ticket stapled to it", 'xcrun', 'stapler', 'validate', app_path)
        end

        UI.success("Verified code signing of #{app_paths.length} app bundle(s)")
      end

      def self.verify!(error_message, *command)
        sh(*command, error_callback: ->(_) { UI.user_error!(error_message) })
      end

      def self.verify_authority!(app_path:, expected_authority:)
        details = sh('codesign', '--display', '--verbose=2', app_path)
        return if details.include?("Authority=#{expected_authority}")

        UI.user_error!("#{app_path} is not signed by '#{expected_authority}':\n#{details}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Verify that macOS app bundles are properly code signed and notarized'
      end

      def self.details
        <<~DETAILS
          Verify that the given macOS app bundles are signed, and optionally notarized, so that a build
          that is unsigned or signed with the wrong identity fails the CI job instead of shipping.

          `electron-builder`, in particular, only warns when it can't find a valid signing identity: it
          skips signing and produces an artifact that looks fine until users try to launch it.

          Run with `verify_notarization: false` at a point in the build where the app has been signed
          but not notarized yet, such as from an `electron-builder` `afterSign` hook.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :app_path,
            description: 'The path, or list of paths, to the `.app` bundle(s) to verify',
            is_string: false,
            verify_block: proc do |value|
              UI.user_error!('`app_path` must be a String or an Array of Strings') unless value.is_a?(String) || value.is_a?(Array)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :expected_authority,
            description: 'The signing authority the app is expected to be signed by, e.g. `Developer ID Application: Automattic, Inc. (ABCDE12345)`. ' \
                         + 'When omitted, any valid signature is accepted',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :verify_notarization,
            description: 'Whether to also assert that the app is accepted by Gatekeeper and has a notarization ticket stapled to it',
            type: Boolean,
            default_value: true
          ),
        ]
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :mac
      end
    end
  end
end
