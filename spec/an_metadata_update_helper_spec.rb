require 'tmpdir'
require_relative './spec_helper'

describe Fastlane::Helper::AnStandardMetadataBlock do
  it 'strips any trailing newline when generating the block for a single-line input' do
    Dir.mktmpdir do |dir|
      input = "Single line message with new line\n"

      # Generate the input file to convert to .pot block
      input_path = File.join(dir, 'input')
      File.write(input_path, input)
      # Ensure the input has only one line
      expect(File.read(input_path).lines.count).to eq 1

      # Write the .pot block in a StringIO to bypass the filesystem and have
      # faster tests
      output_io = StringIO.new
      described_class.new('any-key', input_path).generate_block(output_io)

      # Ensure the output matches the expectation: the trailing new line has been stripped.
      #
      # Note that the final new line is intentional. It's part of the formatting at the time of writing.
      expect(output_io.string).to eq <<~EXP
        msgctxt "any-key"
        msgid "Single line message with new line"
        msgstr ""

      EXP
    end
  end

  it 'does not strip a trailing new line when generating the block for a multi-line input' do
    Dir.mktmpdir do |dir|
      input = "Multi-line\nmessage\nwith\ntrailing new line\n"

      # Generate the input file to convert to .pot block
      input_path = File.join(dir, 'input')
      File.write(input_path, input)

      # Write the .pot block in a StringIO to bypass the filesystem and have faster tests
      output_io = StringIO.new
      described_class.new('any-key', input_path).generate_block(output_io)

      # Note that the new line after `msgstr` is intentional. It's part of the formatting at the time of writing.
      expect(output_io.string).to eq <<~'EXP'
        msgctxt "any-key"
        msgid ""
        "Multi-line\n"
        "message\n"
        "with\n"
        "trailing new line\n"
        msgstr ""

      EXP
    end
  end
end
