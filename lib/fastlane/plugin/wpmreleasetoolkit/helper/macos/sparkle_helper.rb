# frozen_string_literal: true

require 'base64'
require 'open3'
require 'openssl'

module Fastlane
  module Helper
    module SparkleHelper
      # Signs the final archive using the sign_update executable from the app's resolved Sparkle release.
      # Capture output directly: sign_update can echo invalid keys in its diagnostics, and Action.sh logs output.
      #
      # @return [String] the canonical base64 EdDSA signature
      def self.sign_update(archive_path:, signing_tool:, private_key:, public_key:)
        key = private_key.to_s.strip
        UI.user_error!('A Sparkle private key is required; set SPARKLE_PRIVATE_KEY or private_key') if key.empty?
        unless canonical_base64?(key, lengths: [32, 96])
          UI.user_error!('Sparkle private key must be base64 for a 32-byte seed or a 96-byte legacy key')
        end

        archive_path = File.expand_path(archive_path)
        signing_tool = File.expand_path(signing_tool)
        stdout, _stderr, status = Open3.capture3(
          { 'SPARKLE_PRIVATE_KEY' => nil }, signing_tool, '-p', '--ed-key-file', '-', archive_path,
          stdin_data: "#{key}\n"
        )
        UI.user_error!('Sparkle sign_update failed; check the signing tool and private key') unless status.success?

        signature = stdout.strip
        validate_ed_signature!(signature)
        verify_signature!(signature: signature, public_key: public_key, archive_path: archive_path)
        signature
      rescue SystemCallError, IOError
        # Do not retain a potentially sensitive exception as the cause in verbose error reports.
        raise FastlaneCore::Interface::FastlaneError.new, 'Unable to run Sparkle sign_update or read the archive', cause: nil
      end

      # Verify against the public key embedded in the app, so a wrong CI key cannot publish an unusable update.
      def self.verify_signature!(signature:, public_key:, archive_path:)
        validate_public_key!(public_key)
        # SubjectPublicKeyInfo for Ed25519: AlgorithmIdentifier (OID 1.3.101.112) and a 32-byte public key.
        key = OpenSSL::PKey.read(['302a300506032b6570032100'].pack('H*') + Base64.strict_decode64(public_key))
        return if key.verify(nil, Base64.strict_decode64(signature), File.binread(archive_path))

        UI.user_error!('Sparkle signature does not verify against the app public key and archive')
      rescue OpenSSL::PKey::PKeyError
        UI.user_error!('Unable to verify the Sparkle signature with the app public key')
      end

      def self.validate_public_key!(value)
        return if canonical_base64?(value, lengths: [32])

        UI.user_error!('Sparkle public key must be canonical base64 for exactly 32 bytes')
      end

      # Validate a signature without accepting whitespace, URL-safe encoding, or noncanonical padding.
      def self.validate_ed_signature!(value)
        return if canonical_base64?(value, lengths: [64])

        UI.user_error!('EdDSA signature must be canonical base64 for exactly 64 bytes')
      end

      def self.canonical_base64?(value, lengths:)
        return false unless value.is_a?(String)

        decoded = Base64.strict_decode64(value)
        lengths.include?(decoded.bytesize) && Base64.strict_encode64(decoded) == value
      rescue ArgumentError
        false
      end
    end
  end
end
