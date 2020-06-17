module Fastlane
  module Helper
    class EncryptionHelper    

      def self.encrypt(plain_text, key)
        # Ensure consistent encoding
        plain_text.force_encoding(Encoding::UTF_8)

        box = RbNaCl::SimpleBox.from_secret_key(key)
        box.encrypt(plain_text)
      end

      def self.decrypt(encrypted, key)
        box = RbNaCl::SimpleBox.from_secret_key(key)
        box.decrypt(encrypted)
      end

      def self.generate_key
        RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes)
      end
    end
  end
end