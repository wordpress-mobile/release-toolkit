# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

describe Fastlane::Helper::PoFileGenerator do
  describe '#generate' do
    context 'with standard entries' do
      it 'generates a single-line entry for simple content' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, 'My App Name')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { app_name: source_path }
          )

          result = generator.generate

          expect(result).to include('msgctxt "app_name"')
          expect(result).to include('msgid "My App Name"')
          expect(result).to include('msgstr ""')
        end
      end

      it 'generates a multiline entry for content with newlines' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'desc.txt')
          File.write(source_path, "Line 1\nLine 2\nLine 3")

          generator = described_class.new(
            release_version: '1.0',
            source_files: { description: source_path }
          )

          result = generator.generate

          expect(result).to include('msgctxt "description"')
          expect(result).to include('msgid ""')
          expect(result).to include('"Line 1\n"')
          expect(result).to include('"Line 2\n"')
          expect(result).to include('"Line 3"')
        end
      end

      it 'strips trailing whitespace from single-line content' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, "App Name  \n")

          generator = described_class.new(
            release_version: '1.0',
            source_files: { app_name: source_path }
          )

          result = generator.generate

          expect(result).to include('msgid "App Name"')
        end
      end

      it 'handles multiple source files' do
        in_tmp_dir do |dir|
          name_path = File.join(dir, 'name.txt')
          File.write(name_path, 'My App')

          keywords_path = File.join(dir, 'keywords.txt')
          File.write(keywords_path, 'app,mobile,tool')

          generator = described_class.new(
            release_version: '1.0',
            source_files: {
              app_name: name_path,
              keywords: keywords_path
            }
          )

          result = generator.generate

          expect(result).to include('msgctxt "app_name"')
          expect(result).to include('msgctxt "keywords"')
        end
      end

      it 'accepts string keys in source_files hash' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'screenshot.txt')
          File.write(source_path, 'Screenshot caption')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { 'app_store_screenshot-1' => source_path }
          )

          result = generator.generate

          expect(result).to include('msgctxt "app_store_screenshot-1"')
        end
      end
    end

    context 'with whats_new entries' do
      it 'generates versioned whats_new entry' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'whats_new.txt')
          File.write(source_path, "- New feature\n- Bug fix")

          generator = described_class.new(
            release_version: '1.23',
            source_files: { whats_new: source_path }
          )

          result = generator.generate

          expect(result).to include('msgctxt "v1.23-whats-new"')
          expect(result).to include('"- New feature\n"')
          expect(result).to include('"- Bug fix\n"')
        end
      end
    end

    context 'with release_note entries' do
      it 'generates versioned release_note entry with version header' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'release_notes.txt')
          File.write(source_path, "- Feature 1\n- Feature 2")

          generator = described_class.new(
            release_version: '1.23',
            source_files: { release_note: source_path }
          )

          result = generator.generate

          expect(result).to include('msgctxt "release_note_0123"')
          expect(result).to include('"1.23:\n"')
          expect(result).to include('"- Feature 1\n"')
          expect(result).to include('"- Feature 2\n"')
        end
      end

      it 'preserves the n-1 release note from existing file' do
        in_tmp_dir do |dir|
          # Create existing PO file with previous release note
          existing_po_path = File.join(dir, 'existing.po')
          existing_content = <<~PO
            msgctxt "release_note_0122"
            msgid "Previous release notes"
            msgstr ""

            msgctxt "release_note_0121"
            msgid "Older release notes"
            msgstr ""
          PO
          File.write(existing_po_path, existing_content)

          # Create new release notes
          source_path = File.join(dir, 'release_notes.txt')
          File.write(source_path, 'New release notes')

          generator = described_class.new(
            release_version: '1.23',
            source_files: { release_note: source_path },
            existing_po_path: existing_po_path
          )

          result = generator.generate

          # Should have new entry
          expect(result).to include('msgctxt "release_note_0123"')
          # Should preserve n-1 entry
          expect(result).to include('msgctxt "release_note_0122"')
          expect(result).to include('msgid "Previous release notes"')
          # Should NOT include older entries
          expect(result).not_to include('release_note_0121')
        end
      end

      it 'handles version 1.0 (wraps to previous major version)' do
        in_tmp_dir do |dir|
          # For version 1.0, the n-1 version is 0.9, so the key is release_note_009
          existing_po_path = File.join(dir, 'existing.po')
          existing_content = <<~PO
            msgctxt "release_note_009"
            msgid "Previous major version notes"
            msgstr ""
          PO
          File.write(existing_po_path, existing_content)

          source_path = File.join(dir, 'release_notes.txt')
          File.write(source_path, 'First release of v1')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { release_note: source_path },
            existing_po_path: existing_po_path
          )

          result = generator.generate

          expect(result).to include('msgctxt "release_note_010"')
          expect(result).to include('msgctxt "release_note_009"')
        end
      end
    end

    context 'with release_note_short entries' do
      it 'generates versioned release_note_short entry' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'release_notes_short.txt')
          File.write(source_path, 'Bug fixes and improvements')

          generator = described_class.new(
            release_version: '2.5',
            source_files: { release_note_short: source_path }
          )

          result = generator.generate

          expect(result).to include('msgctxt "release_note_short_025"')
          expect(result).to include('"2.5:\n"')
        end
      end

      it 'skips empty release_note_short content' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'release_notes_short.txt')
          File.write(source_path, '   ')

          generator = described_class.new(
            release_version: '2.5',
            source_files: { release_note_short: source_path }
          )

          result = generator.generate

          expect(result).not_to include('release_note_short')
        end
      end
    end

    context 'with generated output' do
      it 'ends with a trailing newline' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, 'App')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { name: source_path }
          )

          result = generator.generate

          expect(result).to end_with("\n")
        end
      end

      it 'generates valid PO format that can be parsed' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'content.txt')
          File.write(source_path, "Multi\nLine\nContent")

          generator = described_class.new(
            release_version: '1.0',
            source_files: { content: source_path }
          )

          output_path = File.join(dir, 'output.po')
          generator.write(output_path)

          # Verify the output can be parsed by gettext
          require 'gettext/po'
          require 'gettext/po_parser'

          po = GetText::PO.new
          parser = GetText::POParser.new
          expect { parser.parse_file(output_path, po) }.not_to raise_error

          entry = po.find { |e| e.msgctxt == 'content' }
          expect(entry).not_to be_nil
          # Standard entries strip trailing content but preserve internal newlines
          expect(entry.msgid).to include("Multi\n")
          expect(entry.msgid).to include("Line\n")
          expect(entry.msgid).to include('Content')
        end
      end
    end
  end

  describe '#write' do
    it 'writes the generated content to a file' do
      in_tmp_dir do |dir|
        source_path = File.join(dir, 'name.txt')
        File.write(source_path, 'Test App')

        output_path = File.join(dir, 'output.po')

        generator = described_class.new(
          release_version: '1.0',
          source_files: { name: source_path }
        )

        generator.write(output_path)

        expect(File.exist?(output_path)).to be true
        expect(File.read(output_path)).to include('msgctxt "name"')
      end
    end
  end
end
