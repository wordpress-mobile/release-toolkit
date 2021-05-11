require 'spec_helper.rb'

shared_context 'with temp dir' do
  before do
    @tmpdir_path = Dir.mktmpdir
    @pwd_before_spec_run = Dir.pwd
    Dir.chdir(tmpdir_path)
  end

  after do
    Dir.chdir(pwd_before_spec_run)
    puts "tmp path is #{tmpdir_path}"
    FileUtils.rm_rf(tmpdir_path)
  end

  attr_reader :tmpdir_path
  attr_reader :pwd_before_spec_run
end

describe Fastlane::Helper::ConfigureHelper do
  include_context 'with temp dir'

  describe '#add_file' do
    let(:destination) { 'path/to/destination' }

    it 'shows the user an error when the destination is not ignored in Git' do
      allow(Fastlane::Helper::GitHelper).to receive(:is_ignored?)
        .with(path: destination)
        .and_return(false)

      allow(Fastlane::Helper::FilesystemHelper).to receive(:project_path)
        .and_return(Pathname.new(tmpdir_path))

      expect(Fastlane::UI).to receive(:user_error!)

      described_class.add_file(source: 'path/to/source', destination: destination, encrypt: true)
    end
  end
end
