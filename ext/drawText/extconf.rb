require 'fileutils'
require 'mkmf'
require 'os'

drawTextDirectory = File.dirname(File.absolute_path(__FILE__))
compilationDirectory = Dir.pwd
libDirectory = File.dirname(File.dirname(drawTextDirectory)) + "/lib"

# Swift is needed to compile the extension
find_executable('swift')
find_executable('xcodebuild')

if OS.mac? then

    # Copy the makefile required for compilation
    FileUtils.cp(drawTextDirectory + "/makefile.example", compilationDirectory + "/Makefile")

    system("xcodebuild -project #{drawTextDirectory}/drawText.xcodeproj/ -scheme drawText -derivedDataPath #{compilationDirectory} -configuration RELEASE")

    compiledPath = compilationDirectory + "/Build/Products/Release/drawText"
    destinationPath = libDirectory + "/drawText"

    # Delete and overwrite the binary
    FileUtils.rm_rf(destinationPath)
    FileUtils.cp(compiledPath, destinationPath)

    # Delete and overwrite the bundle file
    FileUtils.rm_rf(libDirectory + "/drawText.bundle")
    FileUtils.touch(File.join(compilationDirectory, 'drawText.' + RbConfig::CONFIG['DLEXT']))
end
