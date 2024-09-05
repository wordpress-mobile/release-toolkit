require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::IosGenerateStringsFileFromCodeAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_generate_strings_file_from_code') }
  let(:sample_project_dir) { File.join(test_data_dir, 'sample-project') }
  let(:app_src_dir) { File.join(sample_project_dir, 'Sources') }
  let(:pods_src_dir) { File.join(sample_project_dir, 'Pods') }

  context 'when building the list of paths' do
    it 'handle paths pointing to (existing) directories' do
      Dir.mktmpdir('a8c-wpmrt-ios_generate_strings_file_from_code-') do |tmp_dir|
        expect(described_class.glob_pattern(tmp_dir)).to eq("#{tmp_dir}/**/*.{m,swift}")
        expect(described_class.glob_pattern("#{tmp_dir}/")).to eq("#{tmp_dir}/**/*.{m,swift}")
        expect(described_class.glob_pattern("#{tmp_dir}/**")).to eq("#{tmp_dir}/**/*.{m,swift}")
      end
    end

    it 'handle strings and globs to directories-like paths' do
      expect(described_class.glob_pattern('./*/foo/')).to eq('./*/foo/**/*.{m,swift}')
      expect(described_class.glob_pattern('./*/foo/')).to eq('./*/foo/**/*.{m,swift}')
      expect(described_class.glob_pattern('./*/foo/**')).to eq('./*/foo/**/*.{m,swift}')
    end

    it 'does not impact the provided path if already pointing to file-like path' do
      expect(described_class.glob_pattern('foo/bar.m')).to eq('foo/bar.m')
      expect(described_class.glob_pattern('./*/foo/bar.swift')).to eq('./*/foo/bar.swift')
      expect(described_class.glob_pattern('foo/*.{swift,m,mm}')).to eq('foo/*.{swift,m,mm}')
    end

    context 'when excluding files by pattern' do
      def test_exclude_patterns(filter:, expected:)
        list = described_class.files_matching(paths: [app_src_dir, pods_src_dir], exclude: filter)
        expected_fullpaths = expected.map { |f| File.join(sample_project_dir, f) }
        expect(list).to eq(expected_fullpaths), "expected: #{expected.inspect}\n     got: #{list.map { |f| f.sub(sample_project_dir, '') }.inspect}"
      end

      it 'excludes files matching filters starting with *' do
        test_exclude_patterns(
          filter: ['*.m', '*View.swift'],
          expected: %w[Sources/AppClass1.swift Pods/SomePod/Sources/PodClass1.swift Pods/SomePod/Sources/PodLocalizedString.swift]
        )
      end

      it 'excludes files matching filters containing * mid-pattern' do
        test_exclude_patterns(
          filter: ['*.m', '*/App*View.swift'],
          expected: %w[Sources/AppClass1.swift Pods/SomePod/Sources/PodClass1.swift Pods/SomePod/Sources/PodLocalizedString.swift Pods/SomePod/Sources/PodSampleView.swift]
        )
      end
    end
  end

  context 'when generating .strings files from code' do
    # Helper method for all the test examples in this context group
    def test_genstrings(params:, expected_dir_name:, expected_logs: nil, expected_failures: nil)
      # Arrange
      allow_fastlane_action_sh # see spec_helper
      cmd_output = []
      allow(FastlaneCore::UI).to receive(:command_output) { |line| cmd_output << line }
      user_errors = []

      Dir.mktmpdir('a8c-wpmrt-ios_generate_strings_file_from_code-') do |tmp_dir|
        clean_abs_dirs = ->(lines) { lines.map { |l| l.sub(tmp_dir, '<tmpdir>').sub(sample_project_dir, '<testdir>') } }

        # Act
        params[:output_dir] = tmp_dir
        return_value = []
        begin
          return_value = run_described_fastlane_action(params)
        rescue FastlaneCore::Interface::FastlaneError => e
          user_errors << e.message
        end

        # Assert: UI.messages, UI.user_error! and return value from the action
        unless expected_failures.nil?
          expect(clean_abs_dirs[user_errors]).to eq(expected_failures)
        end

        unless expected_logs.nil?
          expect(clean_abs_dirs[cmd_output]).to eq(expected_logs)
          expect(clean_abs_dirs[return_value]).to eq(expected_logs)
        end

        # Assert: same list of generated files
        output_files = Dir[File.join(tmp_dir, '*.strings')]
        expected_files = expected_dir_name.nil? ? [] : Dir[File.join(test_data_dir, expected_dir_name, '*.strings')]
        expect(output_files.map { |f| File.basename(f) }.sort).to eq(expected_files.map { |f| File.basename(f) }.sort)

        # Assert: each generated file has expected content
        output_files.each do |generated_file|
          file_basename = File.basename(generated_file)
          expected_file = expected_files.find { |f| File.basename(f) == file_basename }
          expect(File.read(generated_file)).to eq(File.read(expected_file)), "Content of '#{file_basename}' and '#{expected_file}' do not match."
        end
      end
    end

    context 'with swiftui support disabled' do
      it 'scans all the paths provided (e.g. Pods)' do
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: false },
          expected_dir_name: 'expected-pods-noswiftui'
        )
      end

      it 'only scans the provided paths (e.g. if limiting to app folder)' do
        test_genstrings(
          params: { paths: [app_src_dir], quiet: true, swiftui: false },
          expected_dir_name: 'expected-nopods-noswiftui'
        )
      end
    end

    context 'with swiftui support enabled' do
      it 'scans all the paths provided (e.g. Pods)' do
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: true },
          expected_dir_name: 'expected-pods-swiftui'
        )
      end

      it 'only scans the provided paths (e.g. if limiting to app folder)' do
        test_genstrings(
          params: { paths: [app_src_dir], quiet: true, swiftui: true },
          expected_dir_name: 'expected-nopods-swiftui'
        )
      end
    end

    context 'when allowing custom routines' do
      it 'can parse strings from custom routines' do
        test_genstrings(
          params: {
            paths: [app_src_dir, pods_src_dir],
            exclude: ['**/PodLocalizedString.swift'],
            quiet: true,
            swiftui: false,
            routines: 'PodLocalizedString'
          },
          expected_dir_name: 'expected-custom-routine'
        )
      end
    end

    context 'when requesting custom encoding output' do
      it 'errors if invalid encoding provided' do
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: false, output_encoding: 'unicode' },
          expected_dir_name: nil,
          expected_failures: ['unknown encoding name - unicode']
        )
      end

      it 'copies the files unchanged if output encoding is already the default UTF-16LE' do
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: false, output_encoding: 'utf-16le' },
          expected_dir_name: 'expected-pods-noswiftui'
        )
      end

      it 'convert the files to requested output encoding if not the default UTF-16LE' do
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: false, output_encoding: 'utf-8' },
          expected_dir_name: 'expected-utf8-encoding'
        )
      end
    end

    context 'when `genstrings` finds issues' do
      it 'only logs warnings about multiple values in quiet mode' do
        expected_logs = [
          %(Key "app.key5" used with multiple values. Value "app value 5\\nwith multiple lines." kept. Value "app value 5\\nwith multiple lines, and different value than in Swift" ignored.),
        ]
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: false },
          expected_dir_name: 'expected-pods-noswiftui',
          expected_logs: expected_logs
        )
      end

      it 'logs warnings about both multiple values and multiple comments if not in quiet mode' do
        expected_logs = [
          %(Key "app.key5" used with multiple values. Value "app value 5\\nwith multiple lines." kept. Value "app value 5\\nwith multiple lines, and different value than in Swift" ignored.),
          %(genstrings: warning: Key "app.key5" used with multiple comments "App key 5, with value, custom table and placeholder." & "Duplicate declaration of App key 5 between ObjC and Swift,and with a comment even spanning multiple lines!"),
          %(genstrings: warning: Key "pod.key5" used with multiple comments "Duplicate declaration of Pod key 5 between ObjC and Swift,and with a comment even spanning multiple lines!" & "Pod key 5, with value, custom table and placeholder."),
        ]
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: false, swiftui: false },
          expected_dir_name: 'expected-pods-noswiftui',
          expected_logs: expected_logs
        )
      end

      it 'does not fail if any error is in the output when `fail_on_error` is off' do
        expected_logs = [
          %(Key "app.key5" used with multiple values. Value "app value 5\\nwith multiple lines." kept. Value "app value 5\\nwith multiple lines, and different value than in Swift" ignored.),
          %(genstrings: error: bad entry in file <testdir>/Pods/SomePod/Sources/PodLocalizedString.swift (line = 3): Argument is not a literal string.),
        ]
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: false, routines: 'PodLocalizedString', fail_on_error: false },
          expected_dir_name: 'expected-custom-routine',
          expected_logs: expected_logs,
          expected_failures: []
        )
      end

      it 'fails if there is any error in the output in `fail_on_error` mode, even in quiet mode' do
        expected_failures = [
          %(genstrings: error: bad entry in file <testdir>/Pods/SomePod/Sources/PodLocalizedString.swift (line = 3): Argument is not a literal string.),
        ]
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: true, swiftui: false, routines: 'PodLocalizedString', fail_on_error: true },
          expected_dir_name: nil,
          expected_failures: expected_failures
        )
      end

      it 'does not fail if there are warnings but no error in the output, even in `fail_on_error` mode' do
        expected_logs = [
          %(Key "app.key5" used with multiple values. Value "app value 5\\nwith multiple lines." kept. Value "app value 5\\nwith multiple lines, and different value than in Swift" ignored.),
          %(genstrings: warning: Key "app.key5" used with multiple comments "App key 5, with value, custom table and placeholder." & "Duplicate declaration of App key 5 between ObjC and Swift,and with a comment even spanning multiple lines!"),
          %(genstrings: warning: Key "pod.key5" used with multiple comments "Duplicate declaration of Pod key 5 between ObjC and Swift,and with a comment even spanning multiple lines!" & "Pod key 5, with value, custom table and placeholder."),
        ]
        test_genstrings(
          params: { paths: [app_src_dir, pods_src_dir], quiet: false, swiftui: false, fail_on_error: true },
          expected_dir_name: 'expected-pods-noswiftui',
          expected_logs: expected_logs,
          expected_failures: []
        )
      end
    end
  end
end
