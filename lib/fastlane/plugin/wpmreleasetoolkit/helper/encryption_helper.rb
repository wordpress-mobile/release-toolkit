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
        plain_text.force_encoding(Encoding::UTF_8)

        cipher = cipher(OperationType::ENCRYPT)
        cipher.key = key

        encrypted = cipher.update(plain_text)
        encrypted << cipher.final

        encrypted
      end

      def self.decrypt(encrypted, key)
        cipher = cipher(OperationType::DECRYPT)
        cipher.key = key

        decrypted = cipher.update(encrypted)
        decrypted << cipher.final

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
