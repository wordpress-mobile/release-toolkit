describe Fastlane do
  describe Fastlane::FastFile do
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
            described_class.new.parse("lane :test do
              ios_merge_strings_files(
                paths: ['#{inputs[0]}', '#{inputs[1]}'],
                destination: 'output.strings'
              )
            end").runner.execute(:test)
          end

          # Assert
          expect(File).to exist(File.join(tmpdir, 'output.strings'))
          expect(result).to eq(%w[key1 key2])
          expect(messages).to eq([
                                   'Duplicate key found while merging the `.strings` files: `key1`',
                                   'Duplicate key found while merging the `.strings` files: `key2`',
                                 ])
        end
      end
    end
  end
end
