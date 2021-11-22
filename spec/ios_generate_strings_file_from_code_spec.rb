require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::IosGenerateStringsFileFromCodeAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_generate_strings_file_from_code') }
  let(:app_src_dir) { File.join(test_data_dir, 'sample-project', 'Sources') }
  let(:pods_src_dir) { File.join(test_data_dir, 'sample-project', 'Pods') }

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
        expected_fullpaths = expected.map { |f| File.join(test_data_dir, 'sample-project', f) }
        expect(list).to eq(expected_fullpaths), "expected: #{expected.inspect}\n     got: #{list.map { |f| f.gsub(%r{^.*/sample-project/}, '') }.inspect}"
      end

      it 'excludes files matching filters starting with *' do
        test_exclude_patterns(
          filter: ['*.m', '*View.swift'],
          expected: %w[Sources/AppClass1.swift Pods/SomePod/Sources/PodClass1.swift]
        )
      end

      it 'excludes files matching filters containing * mid-pattern' do
        test_exclude_patterns(
          filter: ['*.m', '*/App*View.swift'],
          expected: %w[Sources/AppClass1.swift Pods/SomePod/Sources/PodClass1.swift Pods/SomePod/Sources/PodSampleView.swift]
        )
      end
    end
  end

  context 'when generating .strings files from code' do
    def test_genstrings(paths_to_scan:, quiet:, swiftui:, routines: [], expected_dir_name:, expected_logs: nil)
      # Arrange
      allow_fastlane_action_sh # see spec_helper
      cmd_output = []
      allow(FastlaneCore::UI).to receive(:command_output) { |line| cmd_output << line }

      Dir.mktmpdir('a8c-wpmrt-ios_generate_strings_file_from_code-') do |tmp_dir|
        # Act
        return_value = described_class.run(paths: paths_to_scan, routines: routines, quiet: quiet, swiftui: swiftui, output_dir: tmp_dir)

        output_files = Dir[File.join(tmp_dir, '*.strings')]
        expected_files = Dir[File.join(test_data_dir, expected_dir_name, '*.strings')]

        # Assert: UI.messages and return value from the action
        unless expected_logs.nil?
          expect(cmd_output).to eq(expected_logs)
          expect(return_value).to eq(expected_logs)
        end
        # Assert: same list of generated files
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
        test_genstrings(paths_to_scan: [app_src_dir, pods_src_dir], quiet: true, swiftui: false, expected_dir_name: 'expected-pods-noswiftui')
      end

      it 'only scans the provided paths (e.g. if limiting to app folder)' do
        test_genstrings(paths_to_scan: [app_src_dir], quiet: true, swiftui: false, expected_dir_name: 'expected-nopods-noswiftui')
      end
    end

    context 'with swiftui support enabled' do
      it 'scans all the paths provided (e.g. Pods)' do
        test_genstrings(paths_to_scan: [app_src_dir, pods_src_dir], quiet: true, swiftui: true, expected_dir_name: 'expected-pods-swiftui')
      end

      it 'only scans the provided paths (e.g. if limiting to app folder)' do
        test_genstrings(paths_to_scan: [app_src_dir], quiet: true, swiftui: true, expected_dir_name: 'expected-nopods-swiftui')
      end
    end

    context 'when allowing custom routines' do
      it 'can parse strings from custom routines' do
        test_genstrings(paths_to_scan: [pods_src_dir], quiet: true, swiftui: false, routines: 'PodLocalizedString', expected_dir_name: 'expected-custom-routine')
      end
    end

    context 'when `genstrings` finds warnings' do
      it 'only logs warnings about multiple values in quiet mode' do
        expected_logs = [
          %(Key "app.key5" used with multiple values. Value "app value 5\\nwith multiple lines." kept. Value "app value 5\\nwith multiple lines, and different value than in Swift" ignored.),
        ]
        test_genstrings(
          paths_to_scan: [app_src_dir, pods_src_dir],
          quiet: true,
          swiftui: false,
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
          paths_to_scan: [app_src_dir, pods_src_dir],
          quiet: false,
          swiftui: false,
          expected_dir_name: 'expected-pods-noswiftui',
          expected_logs: expected_logs
        )
      end
    end
  end
end
