require 'openssl'

module Fastlane
  module Helper
    class EncryptionHelper    
      module OperationType
        ENCRYPT = 1
        DECRYPT = 2
      end

      def self.cipher(op_type, key)
        cipher = OpenSSL::Cipher::AES256.new :CBC

        cipher.encrypt if op_type == OperationType::ENCRYPT
        cipher.decrypt if op_type == OperationType::DECRYPT

        cipher.key = key
        cipher
      end

      def self.encrypt(plain_text, key)
        cipher = cipher(OperationType::ENCRYPT, key)

        encrypted = cipher.update(plain_text)
        encrypted << cipher.final

        encrypted
      end

      def self.decrypt(encrypted, key)
        cipher = cipher(OperationType::DECRYPT, key)

        decrypted = cipher.update(encrypted)
        decrypted << cipher.final

        decrypted
      end
    end
  end
end