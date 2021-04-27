require 'fastlane_core/ui/ui'
require 'net/http'
require 'uri'
require 'json'

module CIHelper
  # Triggers a job on CI
  #
  # @param [String] branch The branch on which the job should run
  # @param [Hash] parameters CI provider specific parameters
  #
  def trigger_job(branch:, parameters: nil)
    raise 'Not implemented'
  end

  # Login
  #
  # @return [String] The CI login credentials
  #
  def login
    raise 'Not implemented'
  end

  # Organization
  #
  # @return [String] The organization the repository belongs to
  #
  def organization
    raise 'Not implemented'
  end

  # Repository
  #
  # @return [String] The repository name
  #
  def repository
    raise 'Not implemented'
  end
end

module Fastlane
  module Helper
    class CircleCIHelper
      include CIHelper

      attr_accessor :login, :organization, :repository

      # Initializes CircleCI helper.
      #
      # @param [String] login The CI login credentials. Usually a personal token on CircleCI
      # @param [String] repository The repository name
      # @param [String] organization The organization the repository belongs to
      #
      def initialize(login:, repository:, organization: 'wordpress-mobile')
        @login = login
        @organization = organization
        @repository = repository
      end

      # Command URI
      #
      # @return [String] The CI API URI
      #
      def command_uri
        URI.parse("https://circleci.com/api/v2/project/github/#{@organization}/#{@repository}/pipeline")
      end

      # Triggers a job on CI
      #
      # @param [String] branch The branch on which the job should run
      # @param [Hash] parameters CI provider specific parameters
      # @return [Net::HTTPResponse] The HTTP response
      #
      def trigger_job(branch:, parameters: nil)
        headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Circle-Token' => @login
        }

        Net::HTTP.start(command_uri.host, command_uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Post.new(command_uri.request_uri, headers)
          body = { "branch": branch, "parameters": parameters }
          request.body = body.to_json
          response = http.request(request)
          return response
        end
      end
    end
  end
end
