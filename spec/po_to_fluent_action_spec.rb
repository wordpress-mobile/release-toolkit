# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::PoToFluentAction do
  let(:fake_po_entries) do
    [
      { 'msgid' => 'welcome-message', 'msgstr' => 'Welcome to our app!', 'translator-comments' => 'Welcome text' },
      { 'msgid' => 'error-network', 'msgstr' => 'Network error occurred', 'translator-comments' => 'Error messages' },
    ]
  end

  let(:fake_fluent_content) do
    <<~FLUENT
      # Welcome text
      welcome-message = Welcome to our app!

      # Error messages
      error-network = Network error occurred
    FLUENT
  end

  before do
    # Mock the FluentLocalizationHelper since it has its own tests
    allow(Fastlane::Helper::FluentLocalizationHelper).to receive_messages(
      parse_po_file: fake_po_entries,
      po_to_fluent: fake_fluent_content
    )
  end

  describe 'file validation' do
    it 'errors when input file does not exist' do
      in_tmp_dir do |tmp_dir|
        non_existent_file = '/path/to/non/existent/file.po'
        output_file = File.join(tmp_dir, 'output.ftl')

        expect(FastlaneCore::UI).to receive(:user_error!)
          .with("Input file does not exist: #{non_existent_file}")

        run_described_fastlane_action(
          input_file: non_existent_file,
          output_file: output_file
        )
      end
    end
  end

  describe 'successful conversion' do
    it 'converts PO file to Fluent format and writes output' do
      with_tmp_file(named: 'input.po', content: 'fake po content') do |input_path|
        in_tmp_dir do |tmp_dir|
          output_path = File.join(tmp_dir, 'output.ftl')

          expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:parse_po_file).with(input_path)
          expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:po_to_fluent).with(fake_po_entries)

          result = run_described_fastlane_action(
            input_file: input_path,
            output_file: output_path
          )

          expect(File.exist?(output_path)).to be true
          expect(File.read(output_path, encoding: 'utf-8')).to eq(fake_fluent_content)
          expect(result).to eq(output_path)
        end
      end
    end

    it 'expands relative paths' do
      with_tmp_file(named: 'input.po', content: 'fake po content') do |input_path|
        in_tmp_dir do |tmp_dir|
          relative_input = 'input.po'
          relative_output = 'output.ftl'
          FileUtils.cp(input_path, File.join(tmp_dir, relative_input))

          Dir.chdir(tmp_dir) do
            expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:parse_po_file)
              .with(File.expand_path(relative_input))

            result = run_described_fastlane_action(
              input_file: relative_input,
              output_file: relative_output
            )

            expect(File.exist?(File.expand_path(relative_output))).to be true
            expect(result).to eq(File.expand_path(relative_output))
          end
        end
      end
    end

    it 'displays success message' do
      with_tmp_file(named: 'input.po', content: 'fake po content') do |input_path|
        in_tmp_dir do |tmp_dir|
          output_path = File.join(tmp_dir, 'output.ftl')

          allow(FastlaneCore::UI).to receive(:message)
          allow(FastlaneCore::UI).to receive(:success)

          expect(FastlaneCore::UI).to receive(:message).with('Converting PO file to Fluent format...')
          expect(FastlaneCore::UI).to receive(:success).with("Successfully converted PO file to Fluent: #{output_path}")

          run_described_fastlane_action(
            input_file: input_path,
            output_file: output_path
          )
        end
      end
    end
  end

  describe 'empty content handling' do
    context 'when allow_empty_file is false (default)' do
      it 'does not create output file when content is empty' do
        empty_fluent_content = ''
        allow(Fastlane::Helper::FluentLocalizationHelper).to receive(:po_to_fluent).and_return(empty_fluent_content)

        with_tmp_file(named: 'input.po', content: 'fake po content') do |input_path|
          in_tmp_dir do |tmp_dir|
            output_path = File.join(tmp_dir, 'output.ftl')

            # Allow the initial message and expect the specific empty file message
            allow(FastlaneCore::UI).to receive(:message).with('Converting PO file to Fluent format...')
            expect(FastlaneCore::UI).to receive(:message).with('No translated content found in PO file')

            expect(File.exist?(output_path)).to be false

            result = run_described_fastlane_action(
              input_file: input_path,
              output_file: output_path
            )

            expect(result).to be_nil
          end
        end
      end

      it 'does not create output file when content is whitespace only' do
        whitespace_content = "   \n\t  \n  "
        allow(Fastlane::Helper::FluentLocalizationHelper).to receive(:po_to_fluent).and_return(whitespace_content)

        with_tmp_file(named: 'input.po', content: 'fake po content') do |input_path|
          in_tmp_dir do |tmp_dir|
            output_path = File.join(tmp_dir, 'output.ftl')

            # Allow the initial message and expect the specific empty file message
            allow(FastlaneCore::UI).to receive(:message).with('Converting PO file to Fluent format...')
            expect(FastlaneCore::UI).to receive(:message).with('No translated content found in PO file')

            expect(File.exist?(output_path)).to be false

            result = run_described_fastlane_action(
              input_file: input_path,
              output_file: output_path,
              allow_empty_file: false
            )

            expect(result).to be_nil
          end
        end
      end
    end

    context 'when allow_empty_file is true' do
      it 'creates output file even when content is empty' do
        empty_fluent_content = ''
        allow(Fastlane::Helper::FluentLocalizationHelper).to receive(:po_to_fluent).and_return(empty_fluent_content)

        with_tmp_file(named: 'input.po', content: 'fake po content') do |input_path|
          in_tmp_dir do |tmp_dir|
            output_path = File.join(tmp_dir, 'output.ftl')

            result = run_described_fastlane_action(
              input_file: input_path,
              output_file: output_path,
              allow_empty_file: true
            )

            expect(File.exist?(output_path)).to be true
            expect(File.read(output_path, encoding: 'utf-8')).to eq('')
            expect(result).to eq(output_path)
          end
        end
      end

      it 'creates output file when content is whitespace only' do
        whitespace_content = "   \n\t  \n  "
        allow(Fastlane::Helper::FluentLocalizationHelper).to receive(:po_to_fluent).and_return(whitespace_content)

        with_tmp_file(named: 'input.po', content: 'fake po content') do |input_path|
          in_tmp_dir do |tmp_dir|
            output_path = File.join(tmp_dir, 'output.ftl')

            result = run_described_fastlane_action(
              input_file: input_path,
              output_file: output_path,
              allow_empty_file: true
            )

            expect(File.exist?(output_path)).to be true
            expect(File.read(output_path, encoding: 'utf-8')).to eq(whitespace_content)
            expect(result).to eq(output_path)
          end
        end
      end
    end
  end
end
