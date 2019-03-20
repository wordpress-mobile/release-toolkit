require 'fileutils'

directory = File.dirname(File.absolute_path(__FILE__))

# Copy the files required for compilation
files = {
    "drawText.swift"    => "drawText.swift",
    "makefile.example"  => "Makefile",
}

files.each do |source, destination|

    source = directory + "/" + source
    destination = Dir.pwd + "/" + destination

    unless source == destination then
        FileUtils.cp(source, destination)
    end
end
