require 'spec_helper'

describe Fastlane::Helper::ConfigureHelper do
  describe '#add_file' do
    let(:destination) { 'path/to/destination' }

    it 'shows the user an error when the destination is not ignored in Git' do
      in_tmp_dir do
        allow(Fastlane::Helper::GitHelper).to receive(:is_ignored?)
          .with(path: destination)
          .and_return(false)

        # Currently, we need a Git repository to exists in the hierarchy containing the call site otherwise the tests will end up stuck in some kind of loop (which I haven't fully inspected).
        # That's a reasonable enough assumption to make for the real world usage of this tool.
        # Still, it would be nice to have proper handling of that scenario at some point.
        `git init --initial-branch main || git init`

        expect(Fastlane::UI).to receive(:user_error!)

        described_class.add_file(source: 'path/to/source', destination:, encrypt: true)
      end
    end
  end
end
