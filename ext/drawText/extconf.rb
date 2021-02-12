require 'fileutils'
require 'mkmf'
require 'os'

drawTextDirectory = File.dirname(File.absolute_path(__FILE__))
compilationDirectory = Dir.pwd
libDirectory = File.join(File.dirname(File.dirname(drawTextDirectory)), '/lib')

# Copy the makefile required for compilation
FileUtils.cp(File.join(drawTextDirectory, 'makefile.example'), File.join(compilationDirectory, 'Makefile'))

# Only compile drawText on macOS
unless OS.mac? then
  exit 0
end

# Swift is needed to compile the extension
find_executable('swift')
find_executable('xcodebuild')

system(
  'xcodebuild',
  '-project', File.join(drawTextDirectory, 'drawText.xcodeproj'),
  '-scheme', 'drawText',
  '-derivedDataPath', compilationDirectory,
  '-configuration', 'RELEASE'
)

compiledPath = File.join(compilationDirectory, 'Build', 'Products', 'Release', 'drawText')
destinationPath = File.join(libDirectory, 'drawText')

# Delete and overwrite the binary
FileUtils.rm_rf(destinationPath)
FileUtils.cp(compiledPath, destinationPath)

# Delete and overwrite the bundle file
FileUtils.rm_rf(File.join(libDirectory, 'drawText.bundle'))
FileUtils.touch(File.join(compilationDirectory, 'drawText.' + RbConfig::CONFIG['DLEXT']))
