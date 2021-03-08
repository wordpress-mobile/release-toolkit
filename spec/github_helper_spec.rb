require 'spec_helper.rb'
require 'webmock/rspec'

describe Fastlane::Helper::GithubHelper do
  describe 'download_file_from_release' do
    it 'fails if it does not find the right release on GitHub' do
      stub = stub_request(:get, 'https://raw.githubusercontent.com/repo-test/project-test/1.0/test-file.xml').to_return(:status => [404, "Not Found"])
      expect(subject.download_file_from_release(repository: 'repo-test/project-test', release: '1.0', file_path: 'test-file.xml', download_folder: './')).to be_nil
      expect(stub).to have_been_made.once
    end

    it 'writes the raw content to a file' do
      stub = stub_request(:get, 'https://raw.githubusercontent.com/repo-test/project-test/1.0/test-file.xml').to_return(:status => 200, body: 'my-test-content')
      allow(File).to receive(:open).with('./test-file.xml', 'wb') do | file |
        expect(subject.download_file_from_release(repository: 'repo-test/project-test', release: '1.0', file_path: 'test-file.xml', download_folder: './')).to eq('./test-file.xml')
        expect(file).to receive(:write).with('my-test-content')
        expect(stub).to have_been_made.once
      end
    end
  end
end
