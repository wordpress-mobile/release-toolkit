# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::FluentToPoAction do
  let(:fake_fluent_entries) do
    [
      { 'id' => 'welcome-message', 'value' => 'Welcome to our app!', 'comment' => 'Welcome text' },
      { 'id' => 'error-network', 'value' => 'Network error occurred', 'comment' => 'Error messages' },
    ]
  end

  let(:fake_po_content) do
    <<~PO
      # SOME DESCRIPTIVE TITLE.
      # Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
      # This file is distributed under the same license as the PACKAGE package.
      # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
      #
      msgid ""
      msgstr ""
      "Project-Id-Version: TestProject 1.0\\n"
      "Report-Msgid-Bugs-To: \\n"
      "Language: en-US\\n"
      "MIME-Version: 1.0\\n"
      "Content-Type: text/plain; charset=UTF-8\\n"
      "Content-Transfer-Encoding: 8bit\\n"

      #. Welcome text
      msgid "welcome-message"
      msgstr "Welcome to our app!"

      #. Error messages
      msgid "error-network"
      msgstr "Network error occurred"
    PO
  end

  before do
    # Mock the FluentLocalizationHelper since it has its own tests
    allow(Fastlane::Helper::FluentLocalizationHelper).to receive_messages(
      parse_fluent_file: fake_fluent_entries,
      fluent_to_po: fake_po_content
    )
  end

  describe 'file validation' do
    it 'errors when input file does not exist' do
      in_tmp_dir do |tmp_dir|
        non_existent_file = '/path/to/non/existent/file.ftl'
        output_file = File.join(tmp_dir, 'output.po')

        expect(FastlaneCore::UI).to receive(:user_error!)
          .with("Input file does not exist: #{non_existent_file}")

        run_described_fastlane_action(
          input_file: non_existent_file,
          output_file: output_file,
          locale: 'en-US'
        )
      end
    end
  end

  describe 'successful conversion' do
    it 'converts Fluent file to PO format and writes output' do
      with_tmp_file(named: 'input.ftl', content: 'fake fluent content') do |input_path|
        in_tmp_dir do |tmp_dir|
          output_path = File.join(tmp_dir, 'output.po')

          expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:parse_fluent_file).with(input_path)
          expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:fluent_to_po).with(
            fluent_file: File.basename(input_path),
            fluent_entries: fake_fluent_entries,
            locale: 'en-US',
            project_name: '',
            project_version: ''
          )

          result = run_described_fastlane_action(
            input_file: input_path,
            output_file: output_path,
            locale: 'en-US'
          )

          expect(File.exist?(output_path)).to be true
          expect(File.read(output_path, encoding: 'utf-8')).to eq(fake_po_content)
          expect(result).to eq(output_path)
        end
      end
    end

    it 'passes optional project parameters to helper' do
      with_tmp_file(named: 'input.ftl', content: 'fake fluent content') do |input_path|
        in_tmp_dir do |tmp_dir|
          output_path = File.join(tmp_dir, 'output.po')

          expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:parse_fluent_file).with(input_path)
          expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:fluent_to_po).with(
            fluent_file: File.basename(input_path),
            fluent_entries: fake_fluent_entries,
            locale: 'es-ES',
            project_name: 'MyApp',
            project_version: '2.0'
          )

          result = run_described_fastlane_action(
            input_file: input_path,
            output_file: output_path,
            locale: 'es-ES',
            project_name: 'MyApp',
            project_version: '2.0'
          )

          expect(File.exist?(output_path)).to be true
          expect(result).to eq(output_path)
        end
      end
    end

    it 'expands relative paths' do
      with_tmp_file(named: 'input.ftl', content: 'fake fluent content') do |input_path|
        in_tmp_dir do |tmp_dir|
          relative_input = 'input.ftl'
          relative_output = 'output.po'
          FileUtils.cp(input_path, File.join(tmp_dir, relative_input))

          Dir.chdir(tmp_dir) do
            expect(Fastlane::Helper::FluentLocalizationHelper).to receive(:parse_fluent_file)
              .with(File.expand_path(relative_input))

            result = run_described_fastlane_action(
              input_file: relative_input,
              output_file: relative_output,
              locale: 'en-US'
            )

            expect(File.exist?(File.expand_path(relative_output))).to be true
            expect(result).to eq(File.expand_path(relative_output))
          end
        end
      end
    end

    it 'displays progress and success messages' do
      with_tmp_file(named: 'input.ftl', content: 'fake fluent content') do |input_path|
        in_tmp_dir do |tmp_dir|
          output_path = File.join(tmp_dir, 'output.po')

          allow(FastlaneCore::UI).to receive(:message)
          allow(FastlaneCore::UI).to receive(:success)

          expect(FastlaneCore::UI).to receive(:message).with('Converting Fluent file to PO format...')
          expect(FastlaneCore::UI).to receive(:message).with("Found #{fake_fluent_entries.length} entries in Fluent file")
          expect(FastlaneCore::UI).to receive(:success).with("Successfully converted Fluent file to PO: #{output_path}")

          run_described_fastlane_action(
            input_file: input_path,
            output_file: output_path,
            locale: 'en-US'
          )
        end
      end
    end
  end
end
