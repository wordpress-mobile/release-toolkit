require 'tmpdir'
require_relative './spec_helper'

describe Fastlane::Helper::StandardMetadataBlock do
  it 'strips any trailing newline when generating the block for a single-line input' do
    Dir.mktmpdir do |dir|
      input = "Single line message with new line\n"

      # Generate the input file to convert to .pot block
      input_path = File.join(dir, 'input')
      File.write(input_path, input)
      # Ensure the input has only one line
      expect(File.read(input_path).lines.count).to eq 1

      # Write the .pot block in an output file
      output_path = File.join(dir, 'output')
      File.open(output_path, 'w') do |file|
        described_class.new('any-key', input_path).generate_block(file)
      end

      # Ensure the output matches the expectation: the trailing new line has
      # been stripped.
      #
      # Note that the final new line is intentional. It's part of the
      # formatting at the time of writing.
      expect(File.read(output_path)).to eq <<~EXP
        msgctxt "any-key"
        msgid "Single line message with new line"
        msgstr ""

      EXP
    end
  end
end
