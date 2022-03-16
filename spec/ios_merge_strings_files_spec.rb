require 'spec_helper'

describe Fastlane::Actions::IosMergeStringsFilesAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_l10n_helper') }

  def fixture(name)
    File.join(test_data_dir, name)
  end

  describe '#ios_merge_strings_files' do
    it 'calls the action with the proper parameters and warn and return duplicate keys' do
      # Arrange
      messages = []
      allow(FastlaneCore::UI).to receive(:important) do |message|
        messages.append(message)
      end

      in_tmp_dir do |tmpdir|
        FileUtils.cp(fixture('Localizable-utf16.strings'), tmpdir)

        # Act
        result = run_described_fastlane_action(
          paths_to_merge: { fixture('non-latin-utf16.strings') => nil },
          destination: 'Localizable-utf16.strings'
        )

        # Assert
        expect(File.read('Localizable-utf16.strings')).to eq(File.read(fixture('expected-merged-nonlatin.strings')))
        expect(result).to eq(%w[key1 key2])
        expect(messages).to eq(
          [
            'Duplicate key found while merging the `.strings` files: `key1`',
            'Duplicate key found while merging the `.strings` files: `key2`',
            'Tip: To avoid those key conflicts, you might want to consider providing different prefixes in the `Hash` you used for the `paths:` parameter.',
          ]
        )
      end
    end

    it 'can create the destination file if it did not exist yet' do
      # Arrange
      allow(FastlaneCore::UI).to receive(:important)
      dest_file = 'output.strings'

      in_tmp_dir do |tmpdir|
        # Act
        result = Dir.chdir(tmpdir) do
          run_described_fastlane_action(
            paths_to_merge: { fixture('Localizable-utf16.strings') => nil, fixture('non-latin-utf16.strings') => nil },
            destination: dest_file
          )
        end

        # Assert
        expect(File).to exist(dest_file)
        expect(File.read(dest_file)).to eq(File.read(fixture('expected-merged-nonlatin.strings')))
        expect(result).to eq(%w[key1 key2])
      end
    end
  end
end
