# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Helper::FluentLocalizationHelper do
  let(:test_data_dir) { File.join(__dir__, 'test-data', 'fluent_localization') }
  let(:tmpdir) { Dir.mktmpdir('a8c-fluent-localization-helper-spec-') }

  after do
    FileUtils.remove_entry tmpdir
  end

  def fixture_path(filename)
    File.join(test_data_dir, filename)
  end

  def temp_file_path(filename)
    File.join(tmpdir, filename)
  end

  describe '.parse_fluent_file' do
    context 'with a valid Fluent file' do
      let(:fluent_content) do
        <<~FLUENT
          # Welcome message for new users
          welcome-message = Welcome to our application!

          # Error messages
          error-network = Unable to connect to the network.
          error-invalid-input = The input you provided is invalid.

          # Dynamic content with variables
          greeting = Hello, {$name}!
          item-count = You have {$count} items in your cart.

          simple-message = This is a simple message.
        FLUENT
      end

      it 'parses all entries correctly' do
        with_tmp_file(named: 'test.ftl', content: fluent_content) do |file_path|
          entries = described_class.parse_fluent_file(file_path)

          expect(entries.length).to eq(6)

          # Check first entry with comment
          expect(entries[0].key).to eq('welcome-message')
          expect(entries[0].value).to eq('Welcome to our application!')
          expect(entries[0].comment).to eq('Welcome message for new users')
          expect(entries[0].line_number).to eq(2)

          # Check entry with different comment
          expect(entries[1].key).to eq('error-network')
          expect(entries[1].value).to eq('Unable to connect to the network.')
          expect(entries[1].comment).to eq('Error messages')
          expect(entries[1].line_number).to eq(5)

          # Check entry with variables
          expect(entries[3].key).to eq('greeting')
          expect(entries[3].value).to eq('Hello, {$name}!')
          expect(entries[3].comment).to eq('Dynamic content with variables')
          expect(entries[3].line_number).to eq(9)

          # Check entry without comment (no comment preceding it)
          expect(entries[5].key).to eq('simple-message')
          expect(entries[5].value).to eq('This is a simple message.')
          expect(entries[5].comment).to be_nil
          expect(entries[5].line_number).to eq(12)
        end
      end

      it 'handles multiline comments' do
        fluent_with_multiline_comment = <<~FLUENT
          # This is the first line of a comment
          # This is the second line of a comment
          # This is the third line of a comment
          multiline-comment-key = This has a multiline comment.
        FLUENT

        with_tmp_file(named: 'multiline.ftl', content: fluent_with_multiline_comment) do |file_path|
          entries = described_class.parse_fluent_file(file_path)

          expect(entries.length).to eq(1)
          expect(entries[0].comment).to eq("This is the first line of a comment\nThis is the second line of a comment\nThis is the third line of a comment")
        end
      end

      it 'resets comments on blank lines' do
        fluent_with_separated_comments = <<~FLUENT
          # First comment
          first-key = First value

          # Second comment
          second-key = Second value
        FLUENT

        with_tmp_file(named: 'separated.ftl', content: fluent_with_separated_comments) do |file_path|
          entries = described_class.parse_fluent_file(file_path)

          expect(entries.length).to eq(2)
          expect(entries[0].comment).to eq('First comment')
          expect(entries[1].comment).to eq('Second comment')
        end
      end

      it 'handles entries with equals signs in values' do
        fluent_with_equals = <<~FLUENT
          equation = 2 + 2 = 4
          url = https://example.com?param=value
        FLUENT

        with_tmp_file(named: 'equals.ftl', content: fluent_with_equals) do |file_path|
          entries = described_class.parse_fluent_file(file_path)

          expect(entries.length).to eq(2)
          expect(entries[0].value).to eq('2 + 2 = 4')
          expect(entries[1].value).to eq('https://example.com?param=value')
        end
      end
    end

    context 'with an empty file' do
      it 'returns an empty array' do
        with_tmp_file(named: 'empty.ftl', content: '') do |file_path|
          entries = described_class.parse_fluent_file(file_path)
          expect(entries).to be_empty
        end
      end
    end

    context 'with comments only' do
      it 'returns an empty array' do
        comments_only = <<~FLUENT
          # This is a comment
          # This is another comment

          # Yet another comment
        FLUENT

        with_tmp_file(named: 'comments.ftl', content: comments_only) do |file_path|
          entries = described_class.parse_fluent_file(file_path)
          expect(entries).to be_empty
        end
      end
    end
  end

  describe '.fluent_to_po' do
    let(:fluent_entries) do
      [
        described_class::FluentEntry.new(
          key: 'welcome-message',
          value: 'Welcome to our application!',
          comment: 'Welcome message for new users',
          line_number: 2
        ),
        described_class::FluentEntry.new(
          key: 'greeting',
          value: 'Hello, {$name}!',
          comment: 'Dynamic content with variables',
          line_number: 8
        ),
        described_class::FluentEntry.new(
          key: 'simple-message',
          value: 'This is a simple message.',
          comment: nil,
          line_number: 11
        ),
      ]
    end

    it 'converts Fluent entries to PO format' do
      po_content = described_class.fluent_to_po(
        fluent_file: 'test.ftl',
        fluent_entries: fluent_entries,
        locale: 'en-US',
        project_name: 'Test Project',
        project_version: '1.0.0'
      )

      po_lines = po_content.split("\n").reject(&:empty?)

      # Check header
      expect(po_lines[0]).to eq("# Generated by #{Fastlane::Wpmreleasetoolkit::NAME} (#{Fastlane::Wpmreleasetoolkit::VERSION})")
      expect(po_lines[1]).to eq('msgid ""')
      expect(po_lines[2]).to eq('msgstr ""')
      expect(po_lines[3]).to eq('"Project-Id-Version: Test Project 1.0.0\n"')
      expect(po_lines[4]).to match(/POT-Creation-Date: \d{4}-\d{2}-\d{2} \d{2}:\d{2}[+-]\d{4}/)
      expect(po_lines[5]).to match(/PO-Revision-Date: \d{4}-\d{2}-\d{2} \d{2}:\d{2}[+-]\d{4}/)
      expect(po_lines[6]).to eq('"Language: en-US\n"')
      expect(po_lines[7]).to eq('"MIME-Version: 1.0\n"')
      expect(po_lines[8]).to eq('"Content-Type: text/plain; charset=UTF-8\n"')
      expect(po_lines[9]).to eq('"Content-Transfer-Encoding: 8bit\n"')
      expect(po_lines[10]).to eq('"Plural-Forms: nplurals=2; plural=(n != 1);\n"')

      # Check first entry
      expect(po_lines[11]).to eq('# Welcome message for new users')
      expect(po_lines[12]).to eq('#: test.ftl:2')
      expect(po_lines[13]).to eq('msgid "welcome-message"')
      expect(po_lines[14]).to eq('msgstr "Welcome to our application!"')

      # Check second entry
      expect(po_lines[15]).to eq('# Dynamic content with variables')
      expect(po_lines[16]).to eq('#: test.ftl:8')
      expect(po_lines[17]).to eq('msgid "greeting"')
      expect(po_lines[18]).to eq('msgstr "Hello, {$name}!"')

      # Check third entry
      expect(po_lines[19]).to eq('#: test.ftl:11')
      expect(po_lines[20]).to eq('msgid "simple-message"')
      expect(po_lines[21]).to eq('msgstr "This is a simple message."')
    end

    it 'handles entries without comments' do
      entries_without_comments = [
        described_class::FluentEntry.new(
          key: 'no-comment-key',
          value: 'Value without comment',
          comment: nil,
          line_number: 5
        ),
      ]

      po_content = described_class.fluent_to_po(
        fluent_file: 'test.ftl',
        fluent_entries: entries_without_comments,
        locale: 'fr',
        project_name: 'Test',
        project_version: '1.0'
      )

      po_lines = po_content.split("\n").reject(&:empty?)

      # Check entry
      expect(po_lines[12]).to eq('#: test.ftl:5')
      expect(po_lines[13]).to eq('msgid "no-comment-key"')
      expect(po_lines[14]).to eq('msgstr "Value without comment"')
    end
  end

  describe '.parse_po_file' do
    let(:po_content) do
      <<~PO
        # SOME DESCRIPTIVE TITLE.
        # Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
        # This file is distributed under the same license as the PACKAGE package.
        # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
        #
        msgid ""
        msgstr ""
        "Project-Id-Version: Test Project 1.0.0\\n"
        "Language: fr\\n"
        "MIME-Version: 1.0\\n"
        "Content-Type: text/plain; charset=UTF-8\\n"
        "Content-Transfer-Encoding: 8bit\\n"

        #. Welcome message for new users
        #: test.ftl:2
        msgid "welcome-message"
        msgstr "Bienvenue dans notre application!"

        #. Dynamic content with variables
        #: test.ftl:8
        msgid "greeting"
        msgstr "Bonjour, {$name}!"

        #: test.ftl:11
        msgid "simple-message"
        msgstr "Ceci est un message simple."
      PO
    end

    it 'parses PO file and returns entries' do
      with_tmp_file(named: 'test.po', content: po_content) do |file_path|
        entries = described_class.parse_po_file(file_path)

        expect(entries.length).to eq(3)

        welcome_entry = entries.find { |e| e.msgid == 'welcome-message' }
        expect(welcome_entry.msgstr).to eq('Bienvenue dans notre application!')
        expect(welcome_entry.extracted_comment.to_s).to include('Welcome message for new users')

        greeting_entry = entries.find { |e| e.msgid == 'greeting' }
        expect(greeting_entry.msgstr).to eq('Bonjour, {$name}!')

        simple_entry = entries.find { |e| e.msgid == 'simple-message' }
        expect(simple_entry.msgstr).to eq('Ceci est un message simple.')
      end
    end

    it 'excludes header entries' do
      with_tmp_file(named: 'test.po', content: po_content) do |file_path|
        entries = described_class.parse_po_file(file_path)

        # Should not include the header entry (empty msgid)
        header_entries = entries.select { |e| e.msgid.to_s.empty? }
        expect(header_entries).to be_empty
      end
    end
  end

  describe '.po_to_fluent' do
    let(:po_entries) do
      # Create mock PO entries using doubles to simulate GetText::POEntry objects
      [
        instance_double(GetText::POEntry,
                        msgid: 'welcome-message',
                        msgstr: 'Bienvenue dans notre application!',
                        translator_comment: 'Welcome message for new users'),
        instance_double(GetText::POEntry,
                        msgid: 'greeting',
                        msgstr: 'Bonjour, {$name}!',
                        translator_comment: 'Dynamic content with variables'),
        instance_double(GetText::POEntry,
                        msgid: 'simple-message',
                        msgstr: 'Ceci est un message simple.',
                        translator_comment: nil),
        instance_double(GetText::POEntry,
                        msgid: 'untranslated-key',
                        msgstr: '',
                        translator_comment: 'This should be skipped'),
      ]
    end

    it 'converts PO entries back to Fluent format' do
      fluent_content = described_class.po_to_fluent(po_entries)

      expect(fluent_content).to include('# Welcome message for new users')
      expect(fluent_content).to include('welcome-message = Bienvenue dans notre application!')

      expect(fluent_content).to include('# Dynamic content with variables')
      expect(fluent_content).to include('greeting = Bonjour, {$name}!')

      expect(fluent_content).to include('simple-message = Ceci est un message simple.')

      # Should not include untranslated entries
      expect(fluent_content).not_to include('untranslated-key')
    end

    it 'skips entries with empty translations' do
      fluent_content = described_class.po_to_fluent(po_entries)

      expect(fluent_content).not_to include('untranslated-key')
    end

    it 'handles entries without comments' do
      fluent_content = described_class.po_to_fluent(po_entries)

      # Should include the entry without a comment block
      lines = fluent_content.split("\n")
      simple_message_index = lines.find_index { |line| line.include?('simple-message =') }
      expect(simple_message_index).not_to be_nil

      # The line before should not be a comment
      previous_line = lines[simple_message_index - 1]
      expect(previous_line).not_to start_with('#')
    end

    it 'handles multiline comments' do
      multiline_entry = instance_double(GetText::POEntry,
                                        msgid: 'multiline-comment-key',
                                        msgstr: 'Translated value',
                                        translator_comment: "First line\nSecond line\nThird line")

      fluent_content = described_class.po_to_fluent([multiline_entry])

      expect(fluent_content).to include('# First line')
      expect(fluent_content).to include('# Second line')
      expect(fluent_content).to include('# Third line')
      expect(fluent_content).to include('multiline-comment-key = Translated value')
    end
  end

  describe '.generate_po_header' do
    it 'generates a proper PO header' do
      header = described_class.generate_po_header(
        locale: 'fr-FR',
        project_name: 'Test App',
        project_version: '2.1.0'
      )

      expect(header).to include('Project-Id-Version: Test App 2.1.0')
      expect(header).to include('Language: fr-FR')
      expect(header).to include('Content-Type: text/plain; charset=UTF-8')
      expect(header).to include('Content-Transfer-Encoding: 8bit')
      expect(header).to include('MIME-Version: 1.0')
    end

    it 'includes timestamp information' do
      header = described_class.generate_po_header(
        locale: 'en',
        project_name: 'Test',
        project_version: '1.0'
      )

      expect(header).to match(/POT-Creation-Date: \d{4}-\d{2}-\d{2} \d{2}:\d{2}[+-]\d{4}/)
      expect(header).to match(/PO-Revision-Date: \d{4}-\d{2}-\d{2} \d{2}:\d{2}[+-]\d{4}/)
    end
  end

  describe '.contains_variables?' do
    it 'detects Fluent variables in text' do
      expect(described_class.contains_variables?('Hello, {$name}!')).to be true
      expect(described_class.contains_variables?('You have {$count} items')).to be true
      expect(described_class.contains_variables?('{$var1} and {$var2}')).to be true
    end

    it 'returns false for text without variables' do
      expect(described_class.contains_variables?('Hello, world!')).to be false
      expect(described_class.contains_variables?('Simple message')).to be false
      expect(described_class.contains_variables?('Text with {} empty braces')).to be false
      expect(described_class.contains_variables?('Text with {no dollar} variable')).to be false
    end

    it 'handles edge cases' do
      expect(described_class.contains_variables?('')).to be false
      expect(described_class.contains_variables?('{$}')).to be false
      expect(described_class.contains_variables?('{$var')).to be false
      expect(described_class.contains_variables?('$var}')).to be false
    end
  end

  describe '.get_plural_rule' do
    context 'with common languages' do
      it 'returns correct plural rule for English' do
        rule = described_class.get_plural_rule('en')
        expect(rule).to eq('nplurals=2; plural=(n != 1);')
      end

      it 'returns correct plural rule for English variants' do
        rule = described_class.get_plural_rule('en-US')
        expect(rule).to eq('nplurals=2; plural=(n != 1);')
      end

      it 'handles Chinese (singular-only language)' do
        rule = described_class.get_plural_rule('zh')
        expect(rule).to eq('nplurals=1; plural=0;')
      end

      it 'handles Chinese variants' do
        rule = described_class.get_plural_rule('zh-CN')
        expect(rule).to eq('nplurals=1; plural=0;')
      end

      it 'returns rule for Slavic languages like Russian' do
        rule = described_class.get_plural_rule('ru')
        # Russian actually has 4 plural forms in modern CLDR data
        expect(rule).to match(/nplurals=[34]; plural=/)
      end

      it 'returns six-form rule for Arabic' do
        rule = described_class.get_plural_rule('ar')
        expect(rule).to eq('nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5);')
      end
    end

    context 'with unsupported or invalid locales' do
      it 'returns fallback rule for unknown languages' do
        rule = described_class.get_plural_rule('unknown-locale')
        expect(rule).to eq('nplurals=2; plural=(n != 1);')
      end

      it 'handles TwitterCldr errors gracefully' do
        # Mock TwitterCldr to raise an error
        allow(TwitterCldr::Formatters::Plurals::Rules).to receive(:all_for).and_raise(StandardError.new('TwitterCldr error'))

        rule = described_class.get_plural_rule('en')
        expect(rule).to eq('nplurals=2; plural=(n != 1);')
      end
    end
  end

  describe 'integration tests' do
    it 'performs round-trip conversion: Fluent -> PO -> Fluent' do
      original_fluent = <<~FLUENT
        # Application title
        app-title = My Awesome App

        # User greeting with variable
        user-greeting = Hello, {$username}!

        # Error message
        error-message = Something went wrong.
      FLUENT

      with_tmp_file(named: 'original.ftl', content: original_fluent) do |fluent_path|
        # Step 1: Parse original Fluent file
        fluent_entries = described_class.parse_fluent_file(fluent_path)
        expect(fluent_entries.length).to eq(3)

        # Step 2: Convert to PO
        po_content = described_class.fluent_to_po(
          fluent_file: 'original.ftl',
          fluent_entries: fluent_entries,
          locale: 'en',
          project_name: 'Test',
          project_version: '1.0'
        )

        # Step 3: Write PO file and parse it back
        with_tmp_file(named: 'converted.po', content: po_content) do |po_path|
          po_entries = described_class.parse_po_file(po_path)

          # Step 4: Convert back to Fluent
          regenerated_fluent = described_class.po_to_fluent(po_entries)

          # Step 5: Verify the content matches (allowing for formatting differences)
          expect(regenerated_fluent).to include('app-title = My Awesome App')
          expect(regenerated_fluent).to include('user-greeting = Hello, {$username}!')
          expect(regenerated_fluent).to include('error-message = Something went wrong.')
          expect(regenerated_fluent).to include('# Application title')
          expect(regenerated_fluent).to include('# User greeting with variable')
          expect(regenerated_fluent).to include('# Error message')
        end
      end
    end
  end
end
