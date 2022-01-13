require 'spec_helper'

describe Fastlane::Actions::GpUpdateMetadataSourceAction do
  it 'works' do
    Dir.mktmpdir do |dir|
      # Reminder: you can stub Fastlane stuff with calls like
      # expect(FastlaneCore::UI).to receive(:success).with('Done')

      # 1: Create tmp location for the po file
      #
      # Note, can't use StringIO.new because of implementation details:
      #
      # Failure/Error: "#{File.dirname(orig_file_path)}/#{File.basename(orig_file_path, '.*')}.tmp"
      output_path = File.join(dir, 'output.po')
      # Also note: The file must exist already
      dummy_text = <<~PO
        msgctxt "key1"
        msgid "this value should change"
        msgstr ""
        msgctxt "key2"
        msgid "this value should change"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      # 2: read a few sources
      file_1_path = File.join(dir, '1.txt')
      File.write(file_1_path, 'value 1')
      file_2_path = File.join(dir, '2.txt')
      File.write(file_2_path, 'value 2')

      described_class.run(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          key1: file_1_path,
          key2: file_2_path
        }
      )

      # 3: compare
      # notice that the new line after each block is added by the conversion
      expected = <<~PO
        msgctxt "key1"
        msgid "value 1"
        msgstr ""

        msgctxt "key2"
        msgid "value 2"
        msgstr ""

      PO
      expect(File.read(output_path)).to eq(expected)
    end
  end
end
