require 'spec_helper'

describe Fastlane::Actions::IosUpdateReleaseNotesAction do
  let(:release_notes_txt) { File.join(File.dirname(__FILE__), 'RELEASE-NOTES.txt') }

  after do
    FileUtils.remove_entry release_notes_txt
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
  end
end
