require 'fastlane_core/ui/ui'
require 'net/http'
require 'uri'
require 'json'

module CIHelper
    def trig_job(branch, parameters=nil)
      raise "Not implemented"
    end

    def login
        raise "Not implemented"
    end

    def organization
        raise "Not implemented"
    end

    def repository 
        raise "Not implemented"
    end
end

module Fastlane
    module Helper
        class CircleCIHelper 
            include CIHelper

            attr_accessor :login, :organization, :repository

            def initialize(login, repository, organization = "wordpress-mobile")
                @login = login
                @organization = organization
                @repository = repository
            end 

            def command_uri
                URI.parse("https://circleci.com/api/v2/project/github/#{@organization}/#{@repository}/pipeline")
            end

            def trig_job(branch, parameters=nil)
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
