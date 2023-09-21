require 'json'
require_relative 'file_reference'

module Fastlane
  class Configuration
    attr_accessor :project_name, :branch, :pinned_hash, :files_to_copy, :file_dependencies

    def initialize(params = {})
      self.project_name = params[:project_name] || Fastlane::Helper::FilesystemHelper.project_path.basename.to_s
      self.branch = params[:branch] || ''
      self.pinned_hash = params[:pinned_hash] || ''
      self.files_to_copy = (params[:files_to_copy] || []).map { |f| FileReference.new(f) }
      self.file_dependencies = params[:file_dependencies] || []
    end

    def self.from_file(path)
      json = JSON.parse(File.read(path), symbolize_names: true)
      new(json)
    end

    def save_to_file(path)
      File.write(path, JSON.pretty_generate(to_hash))
    end

    def add_file_to_copy(source, destination, encrypt: false)
      file = FileReference.new(file: source, destination:, encrypt:)
      files_to_copy << file
    end

    def to_hash
      {
        project_name:,
        branch:,
        pinned_hash:,
        files_to_copy: files_to_copy.map { |f| f.to_hash },
        file_dependencies:
      }
    end
  end
end
