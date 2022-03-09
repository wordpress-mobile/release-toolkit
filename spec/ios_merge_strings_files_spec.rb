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
      inputs = ['Localizable-utf16.strings', 'non-latin-utf16.strings']

      Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmpdir|
        inputs.each { |f| FileUtils.cp(fixture(f), tmpdir) }

        # Act
        result = Dir.chdir(tmpdir) do
          run_described_fastlane_action(
            paths: { inputs[0] => nil, inputs[1] => nil },
            destination: 'output.strings'
          )
        end

        # Assert
        expect(File).to exist(File.join(tmpdir, 'output.strings'))
        expect(result).to eq(%w[key1 key2])
        expect(messages).to eq(
          [
            'Duplicate key found while merging the `.strings` files: `key1`',
            'Duplicate key found while merging the `.strings` files: `key2`',
          ]
        )
      end
    end

    it 'merges in-place if no destination is provided' do
      # Arrange
      allow(FastlaneCore::UI).to receive(:important)
      inputs = ['Localizable-utf16.strings', 'non-latin-utf16.strings']

      in_tmp_dir do |tmpdir|
        inputs.each { |f| FileUtils.cp(fixture(f), tmpdir) }

        # Act
        result = Dir.chdir(tmpdir) do
          run_described_fastlane_action(
            paths: { inputs[0] => nil, inputs[1] => nil }
          )
        end

        # Assert
        derived_output_file = File.join(tmpdir, inputs[0])
        expect(File).to exist(derived_output_file)
        expect(File.read(derived_output_file)).to eq(File.read(fixture('expected-merged-nonlatin.strings')))
        expect(result).to eq(%w[key1 key2])
      end
    end
  end
end
