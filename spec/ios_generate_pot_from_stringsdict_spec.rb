# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Actions::IosGeneratePotFromStringsdictAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'stringsdict') }

  def fixture(name)
    File.join(test_data_dir, name)
  end

  it 'generates a .pot file and returns the number of plural entries' do
    in_tmp_dir do |dir|
      output = File.join(dir, 'out.pot')
      result = run_described_fastlane_action(
        stringsdict_paths: fixture('Localizable.stringsdict'),
        output_path: output
      )

      expect(result).to eq(3)
      expect(File).to exist(output)
      content = File.read(output)
      expect(content).to include('msgid_plural "%d files selected"')
      expect(content).to include('msgctxt "photos_and_albums:photos"')
    end
  end

  it 'accepts an array of source paths' do
    in_tmp_dir do |dir|
      output = File.join(dir, 'out.pot')
      result = run_described_fastlane_action(
        stringsdict_paths: [fixture('simple.stringsdict'), fixture('Localizable.stringsdict')],
        output_path: output
      )
      expect(result).to eq(4)
    end
  end

  it 'raises a user error when a source file does not exist' do
    in_tmp_dir do |dir|
      expect do
        run_described_fastlane_action(
          stringsdict_paths: File.join(dir, 'missing.stringsdict'),
          output_path: File.join(dir, 'out.pot')
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Stringsdict file not found/)
    end
  end
end
