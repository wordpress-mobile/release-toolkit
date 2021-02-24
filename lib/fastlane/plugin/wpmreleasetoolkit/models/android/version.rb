module ReleaseToolkit
  module Models
    module Android
      # An Android Version tuple, consisting of a version name and code.
      #
      class Version
        # [VersionName] version name
        attr_reader :name
        # [Integer] version code
        attr_reader :code

        # @param [VersionName, String] name The versionName of this version tuple
        # @param [String, Integer] code The versionCode of this version tuple
        #
        def initialize(name:, code:)
          @name = name.is_a?(VersionName) ? name : VersionName.from_string(name)
          @code = code&.to_i
        end
      end
    end
  end
end
