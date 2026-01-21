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

      it 'skips empty whats_new content' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'whats_new.txt')
          File.write(source_path, '   ')

          generator = described_class.new(
            release_version: '1.23',
            source_files: { whats_new: source_path }
          )

          result = generator.generate

          expect(result).not_to include('whats-new')
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

    context 'with header generation' do
      it 'generates a header with standard PO fields' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, 'Test App')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { name: source_path }
          )

          result = generator.generate

          expect(result).to include('MIME-Version: 1.0')
          expect(result).to include('Content-Type: text/plain; charset=UTF-8')
          expect(result).to include('Content-Transfer-Encoding: 8bit')
          expect(result).to include('Plural-Forms: nplurals=2; plural=n != 1;')
          expect(result).to include('X-Generator: fastlane-plugin-wpmreleasetoolkit')
        end
      end

      it 'includes PO-Revision-Date with current timestamp' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, 'Test App')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { name: source_path }
          )

          result = generator.generate

          # Should contain a date in YYYY-MM-DD format
          expect(result).to match(/PO-Revision-Date: \d{4}-\d{2}-\d{2} \d{2}:\d{2}[+-]\d{4}/)
        end
      end

      it 'includes gem version in X-Generator field' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, 'Test App')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { name: source_path }
          )

          result = generator.generate

          expect(result).to include("X-Generator: fastlane-plugin-wpmreleasetoolkit #{Fastlane::Wpmreleasetoolkit::VERSION}")
        end
      end
    end

    context 'with translator comments' do
      it 'adds extracted comment when source_files value is a hash with comment' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'subtitle.txt')
          File.write(source_path, 'Your store in your pocket')

          generator = described_class.new(
            release_version: '1.0',
            source_files: {
              app_store_subtitle: {
                path: source_path,
                comment: 'translators: Limit to 30 characters!'
              }
            }
          )

          result = generator.generate

          expect(result).to include('#. translators: Limit to 30 characters!')
          expect(result).to include('msgctxt "app_store_subtitle"')
        end
      end

      it 'handles multiline comments' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'screenshot.txt')
          File.write(source_path, 'Screenshot text')

          generator = described_class.new(
            release_version: '1.0',
            source_files: {
              'app_store_screenshot-1' => {
                path: source_path,
                comment: "translators: Line one.\nLine two."
              }
            }
          )

          result = generator.generate

          expect(result).to include('#. translators: Line one.')
          expect(result).to include('#. Line two.')
        end
      end

      it 'works with string values for backward compatibility' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, 'My App')

          generator = described_class.new(
            release_version: '1.0',
            source_files: { app_name: source_path }
          )

          result = generator.generate

          expect(result).to include('msgctxt "app_name"')
          expect(result).not_to include('#.')
        end
      end

      it 'mixes string and hash values in source_files' do
        in_tmp_dir do |dir|
          name_path = File.join(dir, 'name.txt')
          File.write(name_path, 'My App')

          subtitle_path = File.join(dir, 'subtitle.txt')
          File.write(subtitle_path, 'Great app')

          generator = described_class.new(
            release_version: '1.0',
            source_files: {
              app_name: name_path,
              app_subtitle: {
                path: subtitle_path,
                comment: 'translators: Keep it short'
              }
            }
          )

          result = generator.generate

          expect(result).to include('msgctxt "app_name"')
          expect(result).to include('msgctxt "app_subtitle"')
          expect(result).to include('#. translators: Keep it short')
        end
      end

      it 'handles hash without comment key' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'name.txt')
          File.write(source_path, 'My App')

          generator = described_class.new(
            release_version: '1.0',
            source_files: {
              app_name: { path: source_path }
            }
          )

          result = generator.generate

          expect(result).to include('msgctxt "app_name"')
          expect(result).not_to include('#.')
        end
      end
    end

    context 'with entry ordering' do
      it 'sorts entries alphabetically by msgctxt' do
        in_tmp_dir do |dir|
          # Create source files in non-alphabetical order
          zebra_path = File.join(dir, 'zebra.txt')
          File.write(zebra_path, 'Zebra content')

          apple_path = File.join(dir, 'apple.txt')
          File.write(apple_path, 'Apple content')

          mango_path = File.join(dir, 'mango.txt')
          File.write(mango_path, 'Mango content')

          generator = described_class.new(
            release_version: '1.0',
            source_files: {
              zebra: zebra_path,
              apple: apple_path,
              mango: mango_path
            }
          )

          result = generator.generate
          msgctxts = result.scan(/msgctxt "([^"]+)"/).flatten

          expect(msgctxts).to eq(%w[apple mango zebra])
        end
      end

      it 'sorts release_note entries with other entries' do
        in_tmp_dir do |dir|
          release_path = File.join(dir, 'release.txt')
          File.write(release_path, 'New notes')

          zebra_path = File.join(dir, 'zebra.txt')
          File.write(zebra_path, 'Zebra content')

          generator = described_class.new(
            release_version: '1.23',
            source_files: {
              zebra: zebra_path,
              release_note: release_path
            }
          )

          result = generator.generate
          msgctxts = result.scan(/msgctxt "([^"]+)"/).flatten

          # release_note entries should be sorted with other entries
          expect(msgctxts).to eq(%w[release_note_0123 zebra])
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

  describe 'error handling' do
    context 'with invalid version format' do
      it 'raises user error for version without minor component' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'release.txt')
          File.write(source_path, 'Notes')

          generator = described_class.new(
            release_version: '1',
            source_files: { release_note: source_path }
          )

          expect { generator.generate }.to raise_error(FastlaneCore::Interface::FastlaneError, /Invalid version format '1'/)
        end
      end

      it 'raises user error for version with non-integer components' do
        in_tmp_dir do |dir|
          source_path = File.join(dir, 'release.txt')
          File.write(source_path, 'Notes')

          generator = described_class.new(
            release_version: 'foo.bar',
            source_files: { release_note: source_path }
          )

          expect { generator.generate }.to raise_error(FastlaneCore::Interface::FastlaneError, /major and minor must be integers/)
        end
      end
    end

    context 'with invalid source_files hash' do
      it 'raises user error when hash is missing :path key' do
        generator = described_class.new(
          release_version: '1.0',
          source_files: {
            app_name: { comment: 'A comment but no path' }
          }
        )

        expect { generator.generate }.to raise_error(FastlaneCore::Interface::FastlaneError, /Hash must contain :path key/)
      end
    end
  end
end
