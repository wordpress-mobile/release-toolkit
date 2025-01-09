# frozen_string_literal: true

require 'openssl'

module Fastlane
  module Helper
    class EncryptionHelper
      module OperationType
        ENCRYPT = 1
        DECRYPT = 2
      end

      def self.cipher(op_type)
        cipher = OpenSSL::Cipher.new('aes-256-cbc')

        cipher.encrypt if op_type == OperationType::ENCRYPT
        cipher.decrypt if op_type == OperationType::DECRYPT

        cipher
      end

      def self.encrypt(plain_text, key)
        # Ensure consistent encoding
        sanitized_plain_text = plain_text.dup.force_encoding(Encoding::UTF_8)

        cipher = cipher(OperationType::ENCRYPT)
        cipher.key = key

        cipher.update(sanitized_plain_text) + cipher.final
      end

      def self.decrypt(encrypted, key)
        cipher = cipher(OperationType::DECRYPT)
        cipher.key = key

        decrypted = cipher.update(encrypted) + cipher.final

        # Ensure consistent encoding
        decrypted.force_encoding(Encoding::UTF_8)

        decrypted
      end

      def self.generate_key
        cipher(OperationType::ENCRYPT).random_key
      end
    end
  end
end
