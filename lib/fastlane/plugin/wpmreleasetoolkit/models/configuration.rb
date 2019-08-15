
require 'json'

module Fastlane
  class Configuration
    attr_accessor :project_name, :branch, :pinned_hash, :files_to_copy, :file_dependencies

    def initialize(params = {})
      self.project_name = params[:project_name] || Fastlane::Helper::FilesystemHelper.project_path.basename.to_s
      self.branch = params[:branch] || ""
      self.pinned_hash = params[:pinned_hash] || ""
      self.files_to_copy = (params[:files_to_copy] || []).map { |f| FileReference.new(f) }
      self.file_dependencies = params[:file_dependencies] || []
    end

    def self.from_file(path)
      json = JSON.parse(File.read(path), { symbolize_names: true })
      self.new(json)
    end

    def save_to_file(path)
      File.write(path, JSON.pretty_generate(to_hash))
    end

    def add_file_to_copy(source, destination)
      file = FileReference.new(file: source, destination: destination)
      self.files_to_copy << file
    end

    private

    def to_hash
      {
        project_name: self.project_name,
        branch: self.branch,
        pinned_hash: self.pinned_hash,
        files_to_copy: self.files_to_copy.map { |f| f.to_hash },
        file_dependencies: self.file_dependencies
      }
    end

    class FileReference
      attr_accessor :file, :destination

      def initialize(params = {})
        self.file = params[:file] || ""
        self.destination = params[:destination] || ""
      end

      def to_hash
        { file: self.file, destination: self.destination }
      end
    end
  end
end
