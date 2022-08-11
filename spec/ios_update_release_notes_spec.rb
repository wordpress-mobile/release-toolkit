require 'spec_helper'

describe Fastlane::Actions::IosUpdateReleaseNotesAction do
  let(:release_notes_txt) { File.join(File.dirname(__FILE__), 'RELEASE-NOTES.txt') }
  let(:changelog_md) { File.join(File.dirname(__FILE__), 'CHANGELOG.md') }

  after do
    FileUtils.rm([release_notes_txt, changelog_md], force: true)
  end

  describe '#ios_update_release_notes' do
    it 'adds a new section on RELEASE-NOTES.txt' do
      # Arrange
      ENV['PROJECT_ROOT_FOLDER'] = File.dirname(__FILE__)
      File.write(release_notes_txt, '')

      # Act
      run_described_fastlane_action(
        new_version: '1.0'
      )

      # Assert
      expect(File.read(release_notes_txt)).to eq("1.1\n-----\n\n\n")
    end

    it 'adds a new section on the given file' do
      # Arrange
      ENV['PROJECT_ROOT_FOLDER'] = File.dirname(__FILE__)
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
