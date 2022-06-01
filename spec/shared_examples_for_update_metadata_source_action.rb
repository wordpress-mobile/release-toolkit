require 'spec_helper'

RSpec.shared_examples 'update_metadata_source_action' do |options|
  it 'updates any block in a given .po file with the values from the given sources' do
    in_tmp_dir do |dir|
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "key1"
        msgid "this value should change"
        msgstr ""
        msgctxt "key2"
        msgid "this value should change, too"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      file_1_path = File.join(dir, '1.txt')
      File.write(file_1_path, 'value 1')
      file_2_path = File.join(dir, '2.txt')
      File.write(file_2_path, 'value 2')

      run_described_fastlane_action(
        po_file_path: output_path,
        release_version: '1.0',
        source_files: {
          key1: file_1_path,
          key2: file_2_path
        }
      )

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

  it 'combines the given `release_version` and `whats_new` parameter into a new block' do
    pending 'this currently fails; in the long run, we might consolidate `whats_new` with `release_notes`' if options[:whats_new_fails]

    in_tmp_dir do |dir|
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "v1.0-whats-new"
        msgid "this will not change"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      whats_new_path = File.join(dir, 'whats_new.txt')
      File.write(whats_new_path, "- something new\n- something else new")

      run_described_fastlane_action(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          whats_new: whats_new_path
        }
      )

      expected = <<~'PO'
        msgctxt "v1.23-whats-new"
        msgid ""
        "- something new\n"
        "- something else new\n"
        msgstr ""

      PO
      expect(File.read(output_path)).to eq(expected)
    end
  end

  it 'adds entries passed as input even if not part of the original `.po` file' do
    pending 'this currently fails and will be addressed as part of the upcoming refactor/rewrite of the functionality'

    in_tmp_dir do |dir|
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "key1"
        msgid "this value should change"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      # 2: Create source files with value to insert in the .po
      file_1_path = File.join(dir, '1.txt')
      File.write(file_1_path, 'value 1')
      file_2_path = File.join(dir, '2.txt')
      File.write(file_2_path, 'value 2')

      run_described_fastlane_action(
        po_file_path: output_path,
        release_version: '1.0',
        source_files: {
          key1: file_1_path,
          key2: file_2_path
        }
      )

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

  it 'combines the given `release_version` and `release_notes` in a new block, keeps the n-1 ones, and deletes the others' do
    in_tmp_dir do |dir|
      output_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
        msgctxt "release_note_0122"
        msgid "previous version notes required to have current one added"
        msgstr ""
        msgctxt "release_note_0121"
        msgid "this older release notes block should be removed"
        msgstr ""
        msgctxt "release_note_0120"
        msgid "this older release notes block should be removed"
        msgstr ""
      PO
      File.write(output_path, dummy_text)

      release_notes_path = File.join(dir, 'release_notes.txt')
      File.write(release_notes_path, "- release notes\n- more release notes")

      run_described_fastlane_action(
        po_file_path: output_path,
        release_version: '1.23',
        source_files: {
          release_note: release_notes_path
        }
      )

      expected = <<~'PO'
        msgctxt "release_note_0123"
        msgid ""
        "1.23:\n"
        "- release notes\n"
        "- more release notes\n"
        msgstr ""

        msgctxt "release_note_0122"
        msgid "previous version notes required to have current one added"
        msgstr ""
      PO
      expect(File.read(output_path).inspect).to eq(expected.inspect)
    end
  end
end
