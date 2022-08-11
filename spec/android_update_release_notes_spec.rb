require 'spec_helper'

describe Fastlane::Actions::AndroidUpdateReleaseNotesAction do
  describe '#android_update_release_notes' do
    it 'adds a new section on RELEASE-NOTES.txt' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        ENV['PROJECT_ROOT_FOLDER'] = tmp_dir
        release_notes_txt = File.join(tmp_dir, 'RELEASE-NOTES.txt')
        File.write(release_notes_txt, ANDROID_FAKE_CONTENT)

        # Act
        run_described_fastlane_action(
          new_version: '1.0'
        )

        # Assert
        expect(File.read(release_notes_txt)).to eq(ANDROID_NEW_SECTION + ANDROID_FAKE_CONTENT)
      end
    end

    it 'adds a new section on the given file' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        ENV['PROJECT_ROOT_FOLDER'] = tmp_dir
        changelog_md = File.join(tmp_dir, 'CHANGELOG.md')
        File.write(changelog_md, ANDROID_FAKE_CONTENT)

        # Act
        run_described_fastlane_action(
          new_version: '1.0',
          release_notes_file_path: changelog_md
        )

        # Assert
        expect(File.read(changelog_md)).to eq(ANDROID_NEW_SECTION + ANDROID_FAKE_CONTENT)
      end
    end
  end
end

ANDROID_FAKE_CONTENT = <<~CONTENT.freeze
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

ANDROID_NEW_SECTION = <<~CONTENT.freeze
  1.1
  -----


CONTENT
