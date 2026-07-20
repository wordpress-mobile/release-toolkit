# frozen_string_literal: true

module Fastlane
  module Actions
    class MacosVerifyCodeSigningAction < Action
      def self.run(params)
        paths = Array(params[:artifact_path])
        UI.user_error!('No artifact to verify: `artifact_path` is empty') if paths.empty?

        paths.each do |path|
          UI.user_error!("There is no artifact at #{path}") unless File.exist?(path)

          UI.message("Verifying #{path}")

          case File.extname(path).downcase
          when '.app'
            verify_app_bundle(path: path, expected_authority: params[:expected_authority], verify_notarization: params[:verify_notarization])
          when '.dmg'
            verify_disk_image(path: path, expected_authority: params[:expected_authority], verify_notarization: params[:verify_notarization])
          else
            UI.user_error!("Don't know how to verify #{path}. Supported artifacts are `.app` bundles and `.dmg` disk images")
          end
        end

        UI.success("Verified #{paths.length} artifact(s)")
      end

      def self.verify_app_bundle(path:, expected_authority:, verify_notarization:)
        verify!("The code signature of #{path} is not valid", 'codesign', '--verify', '--deep', '--strict', '--verbose=2', path)
        verify_authority!(path: path, expected_authority: expected_authority) unless expected_authority.nil?

        return unless verify_notarization

        verify!("#{path} was rejected by Gatekeeper", 'spctl', '--assess', '--type', 'execute', '--verbose=2', path)
        verify!("#{path} has no notarization ticket stapled to it", 'xcrun', 'stapler', 'validate', path)
      end

      # Unlike an app bundle, a disk image is often not signed at all — `electron-builder`, for one,
      # only signs the app inside it. Gatekeeper then rejects the image itself with `no usable
      # signature` even when it carries a notarization ticket, so the stapled ticket is the only
      # check that means anything for an unsigned image.
      #
      def self.verify_disk_image(path:, expected_authority:, verify_notarization:)
        if signed?(path)
          verify_authority!(path: path, expected_authority: expected_authority) unless expected_authority.nil?
          verify!("#{path} was rejected by Gatekeeper", 'spctl', '--assess', '--type', 'open', '--context', 'context:primary-signature', '--verbose=2', path) if verify_notarization
        else
          UI.important("#{path} is not signed — skipping its signature checks. Only the app it contains carries a signature.")
        end

        verify!("#{path} has no notarization ticket stapled to it", 'xcrun', 'stapler', 'validate', path) if verify_notarization
      end

      # Distinguishes an artifact that carries no signature at all from one whose signature is
      # broken: the former is expected for a disk image, the latter always a failure.
      #
      def self.signed?(path)
        exitstatus, output = sh('codesign', '--verify', '--strict', '--verbose=2', path) { |status, result, _| [status.exitstatus, result] }

        return true if exitstatus.zero?
        return false if output.include?('not signed at all')

        UI.user_error!("The code signature of #{path} is not valid:\n#{output}")
      end

      def self.verify!(error_message, *command)
        sh(*command, error_callback: ->(_) { UI.user_error!(error_message) })
      end

      def self.verify_authority!(path:, expected_authority:)
        details = sh('codesign', '--display', '--verbose=2', path)
        return if details.include?("Authority=#{expected_authority}")

        UI.user_error!("#{path} is not signed by '#{expected_authority}':\n#{details}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Verify that macOS artifacts are properly code signed and notarized'
      end

      def self.details
        <<~DETAILS
          Verify that the given macOS artifacts are signed, and optionally notarized.

          The checks that apply are picked from the artifact's extension:

          - `.app` — the signature is valid and satisfies its designated requirement, Gatekeeper accepts
            the bundle for execution, and a notarization ticket is stapled to it.
          - `.dmg` — a notarization ticket is stapled to the image.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :artifact_path,
            description: 'The path, or list of paths, to the `.app` bundle(s) or `.dmg` disk image(s) to verify',
            is_string: false,
            verify_block: proc do |value|
              next if value.is_a?(String)
              next if value.is_a?(Array) && value.all?(String)

              UI.user_error!('`artifact_path` must be a String or an Array of Strings')
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :expected_authority,
            description: 'The signing authority the artifact is expected to be signed by, e.g. `Developer ID Application: Automattic, Inc. (ABCDE12345)`. ' \
                         + 'When omitted, any valid signature is accepted',
            type: String,
            optional: true,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :verify_notarization,
            description: 'Whether to also assert that the artifact is accepted by Gatekeeper and has a notarization ticket stapled to it',
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
