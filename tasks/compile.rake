
require "rake/extensiontask"

spec = Gem::Specification.load('fastlane-plugin-wpmreleasetoolkit.gemspec')

class SwiftBinaryTask < Rake::ExtensionTask

  def init(name = nil, gem_spec = nil)
    super
      @source_pattern = "*.swift"
	  @compiled_pattern = "^[A-Za-z][^.]*$"
  end

  def binary(platform = nil)
    "#{name}"
  end
end

SwiftBinaryTask.new("drawText", spec) do |ext|
end
