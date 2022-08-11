require 'spec_helper'

describe Fastlane::Actions::AndroidUpdateReleaseNotesAction do
  describe '#android_update_release_notes' do
    it 'adds a new section on RELEASE-NOTES.txt' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        ENV['PROJECT_ROOT_FOLDER'] = tmp_dir
        release_notes_txt = File.join(tmp_dir, 'RELEASE-NOTES.txt')
        File.write(release_notes_txt, '')

        # Act
        run_described_fastlane_action(
          new_version: '1.0'
        )

        # Assert
        expect(File.read(release_notes_txt)).to eq("1.1\n-----\n\n\n")
      end
    end

    it 'adds a new section on the given file' do
      in_tmp_dir do |tmp_dir|
        # Arrange
        ENV['PROJECT_ROOT_FOLDER'] = tmp_dir
        changelog_md = File.join(tmp_dir, 'CHANGELOG.md')
        File.write(changelog_md, '')

        # Act
        run_described_fastlane_action(
          new_version: '1.0',
          release_notes_file_path: changelog_md
        )

        # Assert
        expect(File.read(changelog_md)).to eq("1.1\n-----\n\n\n")
      end
    end
  end
end
