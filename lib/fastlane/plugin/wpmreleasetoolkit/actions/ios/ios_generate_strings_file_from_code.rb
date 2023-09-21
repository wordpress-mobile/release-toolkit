module Fastlane
  module Actions
    class IosGenerateStringsFileFromCodeAction < Action
      def self.run(params)
        files = files_matching(paths: params[:paths], exclude: params[:exclude])
        flags = [('-q' if params[:quiet]), ('-SwiftUI' if params[:swiftui])].compact
        flags += Array(params[:routines]).flat_map { |routine| ['-s', routine] }
        cmd = ['genstrings', '-o', params[:output_dir], *flags, *files]
        out = Actions.sh_control_output(*cmd, print_command: FastlaneCore::Globals.verbose?, print_command_output: true)
        out = out.scrub.strip.split("\n")
        errors = out.select { |line| line.include?('genstrings: error: ') }
        UI.user_error!(errors.join("\n")) unless !params[:fail_on_error] || errors.empty?
        out
      end

      # Adds the proper `**/*.{m,swift}` to the list of paths
      def self.glob_pattern(path)
        if path.end_with?('**') || path.end_with?('**/')
          File.join(path, '*.{m,swift}')
        elsif File.directory?(path) || path.end_with?('/')
          File.join(path, '**', '*.{m,swift}')
        else
          path
        end
      end

      def self.files_matching(paths:, exclude:)
        globbed_paths = paths.map { |p| glob_pattern(p) }
        Dir.glob(globbed_paths).reject do |file|
          exclude&.any? { |ex| File.fnmatch?(ex, file) }
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generate the `.strings` files from your Objective-C and Swift code'
      end

      def self.details
        <<~DETAILS
          Uses `genstrings` to generate the `.strings` files from your Objective-C and Swift code.
          (especially `Localizable.strings` but it could generate more if the code uses custom tables).

          You can provide a list of paths to scan but also paths to exclude. Both supports glob patterns.
          You can also optionally provide a list of custom "routines" (aka macros or functions) that
          `genstrings` should parse in addition to the usual `NSLocalizedString`. (see `-s` option of `genstrings`).

          Tip: support for custom routines is useful if some of your targets define a helper function e.g.
          `PodLocalizedString` to wrap calls to `Bundle.localizedString(forKey: key, value: value, table: nil)`,
          just like the build-in `NSLocalizedString` does, but providing a custom bundle to look up the strings from.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :paths,
                                       env_name: 'FL_IOS_GENERATE_STRINGS_FILE_FROM_CODE_PATHS',
                                       description: 'Array of paths to scan for `.m` and `.swift` files. The entries can also contain glob patterns',
                                       type: Array,
                                       default_value: ['.']),
          FastlaneCore::ConfigItem.new(key: :exclude,
                                       env_name: 'FL_IOS_GENERATE_STRINGS_FILE_FROM_CODE_EXCLUDE',
                                       description: 'Array of paths or glob patterns to exclude from scanning',
                                       type: Array,
                                       default_value: []),
          FastlaneCore::ConfigItem.new(key: :routines,
                                       env_name: 'FL_IOS_GENERATE_STRINGS_FILE_FROM_CODE_ROUTINES',
                                       description: 'Base name of the alternate methods to be parsed in addition to the standard `NSLocalizedString()` one. See the `-s` option in `man genstrings`',
                                       type: Array,
                                       default_value: []),
          FastlaneCore::ConfigItem.new(key: :quiet,
                                       env_name: 'FL_IOS_GENERATE_STRINGS_FILE_FROM_CODE_QUIET',
                                       description: 'In quiet mode, `genstrings` will log warnings about duplicate values, but not about duplicate comments',
                                       type: Boolean,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :swiftui,
                                       env_name: 'FL_IOS_GENERATE_STRINGS_FILE_FROM_CODE_SWIFTUI',
                                       description: "Should we include SwiftUI's `Text()` when parsing code with `genstrings`",
                                       type: Boolean,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :output_dir,
                                       env_name: 'FL_IOS_GENERATE_STRINGS_FILE_FROM_CODE_OUTPUT_DIR',
                                       description: 'The path to the directory where the generated `.strings` files should be created',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :fail_on_error,
                                       env_name: 'FL_IOS_GENERATE_STRINGS_FILE_FROM_CODE_FAIL_ON_ERROR',
                                       description: 'If true, will fail with user_error! if `genstrings` printed any error while parsing',
                                       type: Boolean,
                                       default_value: true),
        ]
      end

      def self.return_type
        # Describes what type of data is expected to be returned
        # see RETURN_TYPES in https://github.com/fastlane/fastlane/blob/master/fastlane/lib/fastlane/action.rb
        :array_of_strings
      end

      def self.return_value
        'List of warning lines generated by genstrings on stdout'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end
    end
  end
end
