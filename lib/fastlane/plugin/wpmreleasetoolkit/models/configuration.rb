
require 'json'

module Fastlane
  class Configuration
    attr_accessor :branch, :pinned_hash, :files_to_copy, :file_dependencies

    def initialize(branch = "", pinned_hash = "", files_to_copy = [], file_dependencies = [])
      self.branch = branch
      self.pinned_hash = pinned_hash
      self.files_to_copy = files_to_copy
      self.file_dependencies = file_dependencies
    end

    def self.from_file(path)
      json = JSON.parse(File.read(path), { symbolize_names: true })
      self.new(json[:branch], json[:pinned_hash], json[:files_to_copy], json[:file_dependencies])
    end

    def save_to_file(path)
      File.write(path, JSON.pretty_generate(to_hash))
    end

    private

    def to_hash
      {
        branch: self.branch,
        pinned_hash: self.pinned_hash,
        files_to_copy: self.files_to_copy,
        file_dependencies: self.file_dependencies
      }
    end
  end
end
