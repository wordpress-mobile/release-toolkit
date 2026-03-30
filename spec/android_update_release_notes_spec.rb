# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::AndroidUpdateReleaseNotesAction do
  let(:new_section) do
    <<~CONTENT
      1.1
      -----


    CONTENT
  end

  let(:content) do
    <<~CONTENT
      1.0
      -----
      - Item 1 for v1.0
      - Item 2 for v1.0

      // Comment in the middle

      0.9.0
      -----
      - Item 1 for v0.9.0
      - Item 2 for v0.9.0
    CONTENT
  end

  describe '#android_update_release_notes' do
    it 'adds a new section on RELEASE-NOTES.txt' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        release_notes_txt = File.join(tmp_dir, 'RELEASE-NOTES.txt')
        File.write(release_notes_txt, content)

        # Act
        run_described_fastlane_action(
          new_version: '1.0'
        )

        # Assert
        expect(File.read(release_notes_txt)).to eq(new_section + content)
      end
    end

    it 'adds a new section on the given file' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        changelog_md = File.join(tmp_dir, 'CHANGELOG.md')
        File.write(changelog_md, content)

        # Act
        run_described_fastlane_action(
          new_version: '1.0',
          release_notes_file_path: changelog_md
        )

        # Assert
        expect(File.read(changelog_md)).to eq(new_section + content)
      end
    end

    it 'uses next_version directly when provided' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        release_notes_txt = File.join(tmp_dir, 'RELEASE-NOTES.txt')
        File.write(release_notes_txt, content)

        expected_section = <<~CONTENT
          8.10
          -----


        CONTENT

        # Act
        run_described_fastlane_action(
          next_version: '8.10'
        )

        # Assert
        expect(File.read(release_notes_txt)).to eq(expected_section + content)
      end
    end

    it 'prefers next_version over new_version when both are provided' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        release_notes_txt = File.join(tmp_dir, 'RELEASE-NOTES.txt')
        File.write(release_notes_txt, content)

        expected_section = <<~CONTENT
          8.10
          -----


        CONTENT

        # Act
        run_described_fastlane_action(
          new_version: '8.9',
          next_version: '8.10'
        )

        # Assert — next_version wins, not the computed 9.0 from new_version
        expect(File.read(release_notes_txt)).to eq(expected_section + content)
      end
    end

    it 'raises an error when neither new_version nor next_version is provided' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        release_notes_txt = File.join(tmp_dir, 'RELEASE-NOTES.txt')
        File.write(release_notes_txt, content)

        # Act & Assert
        expect do
          run_described_fastlane_action(
            release_notes_file_path: release_notes_txt
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You must provide either `next_version` or `new_version`')
      end
    end
  end
end
