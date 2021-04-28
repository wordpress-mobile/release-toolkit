require 'spec_helper.rb'

describe Fastlane::Helper::ConfigureHelper do

  describe '#add_file' do
    let(:destination) { 'path/to/destination' }

    it 'shows the user an error when the destination is not ignored in Git' do
      allow(Fastlane::Helper::GitHelper).to receive(:is_ignored?)
        .with(path: destination)
        .and_return(false)

      expect(Fastlane::UI).to receive(:user_error!)

      described_class.add_file({ source: 'path/to/source', destination: destination, encrypt: true })
    end
  end
end
