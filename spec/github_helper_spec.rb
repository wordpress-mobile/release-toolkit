require 'spec_helper'
require 'webmock/rspec'

describe Fastlane::Helper::GithubHelper do
  describe 'download_file_from_tag' do
    it 'fails if it does not find the right release on GitHub' do
      stub = stub_request(:get, 'https://raw.githubusercontent.com/repo-test/project-test/1.0/test-file.xml').to_return(status: [404, 'Not Found'])
      expect(described_class.download_file_from_tag(repository: 'repo-test/project-test', tag: '1.0', file_path: 'test-file.xml', download_folder: './')).to be_nil
      expect(stub).to have_been_made.once
    end

    it 'writes the raw content to a file' do
      stub = stub_request(:get, 'https://raw.githubusercontent.com/repo-test/project-test/1.0/test-file.xml').to_return(status: 200, body: 'my-test-content')
      Dir.mktmpdir('a8c-download-repo-file-') do |tmpdir|
        dst_file = File.join(tmpdir, 'test-file.xml')
        expect(described_class.download_file_from_tag(repository: 'repo-test/project-test', tag: '1.0', file_path: 'test-file.xml', download_folder: tmpdir)).to eq(dst_file)
        expect(stub).to have_been_made.once
        expect(File.read(dst_file)).to eq('my-test-content')
      end
    end
  end
end
