require 'spec_helper.rb'
require 'webmock/rspec'

shared_examples "a CI provider" do 
    subject { model }
    it { is_expected.to respond_to(:login) }
    it { is_expected.to respond_to(:organization) }
    it { is_expected.to respond_to(:repository) }
    it { is_expected.to respond_to(:trig_job).with(1..2).argument }
end

describe Fastlane::Helper::CircleCIHelper do
    it_behaves_like "a CI provider" do 
        let(:model) { Fastlane::Helper::CircleCIHelper.new("my_circleci_token", "test_repo") }
    end

    context "initialization" do 
        describe Fastlane::Helper::CircleCIHelper.new("my_circleci_token", "test_repo") do 
            it { is_expected.to have_attributes(:organization => "wordpress-mobile", "repository" => "test_repo", "command_uri" => URI.parse("https://circleci.com/api/v2/project/github/wordpress-mobile/test_repo/pipeline"))}
        end

        describe Fastlane::Helper::CircleCIHelper.new("my_circleci_token", "test_repo", "my_org") do 
            it { is_expected.to have_attributes(:organization => "my_org", "repository" => "test_repo", "command_uri" => URI.parse("https://circleci.com/api/v2/project/github/my_org/test_repo/pipeline"))}
        end
    end

    context "Main Commands" do
        describe Fastlane::Helper::CircleCIHelper.new("my_circleci_token", "test_repo") do 
            it "Trig Job" do  
                stub = stub_request(:post, "https://circleci.com/api/v2/project/github/wordpress-mobile/test_repo/pipeline").with(:body => {"branch":"develop","parameters":nil}, :headers => {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'Circle-Token' => 'my_circleci_token'}).to_return(:body => "efg")
                subject.trig_job("develop")
                expect(stub).to have_been_made.once
            end
        end
    end
end