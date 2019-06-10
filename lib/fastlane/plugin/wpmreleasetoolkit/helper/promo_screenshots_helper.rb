require 'tmpdir'
require 'RMagick'
require 'json'
require 'tempfile'
require 'optparse'
require 'pathname'
require 'progress_bar'
require 'parallel'
require 'jsonlint'

include Magick

module Fastlane
  module Helper
    
    class PromoScreenshots

      def initialize(configFilePath, imageDirectory, translationDirectory, outputDirectory)
        @configFilePath = resolve_path(configFilePath)
        @imageDirectory = resolve_path(imageDirectory)
        @translationDirectory = resolve_path(translationDirectory)
        @outputDirectory = resolve_path(outputDirectory)

        unless @configFilePath.exist? then
          UI.user_error!("Unable to locate configuration file.")
        end

        unless @imageDirectory.exist? then
          UI.user_error!("Unable to locate original image directory.")
        end

        unless @translationDirectory.exist? then
          UI.user_error!("Unable to locate translations directory.")
        end

        begin
          @config = JSON.parse(open(@configFilePath).read)
        rescue
            linter = JsonLint::Linter.new
            linter.check(@configFilePath)
            linter.display_errors

            UI.user_error!("Invalid JSON configuration. See errors in log.")
        end

        # Ensure that the drawText tool is ready to go
        system("bundle exec drawText usage 1>/dev/null 2>/dev/null")
      end

      def create()
        imageDirectories = []

        Dir.chdir(@imageDirectory) do
          imageDirectories = Dir["*"].reject{|o| not File.directory?(o)}.sort
        end

        translationDirectories = []

        Dir.chdir(@translationDirectory) do
          translationDirectories = Dir["*"].reject{|o| not File.directory?(o)}.sort
        end

        languages = imageDirectories & translationDirectories

        UI.message("Creating Promo Screenshots for: #{languages.join(", ")}")

        # Create a hash of devices, keyed by device name
        devices = @config["devices"]
        devices = Hash[devices.map { |device| device["name"] }.zip(devices)]

        # Move global settings from the configuration into variables
        @global_background_color = @config["background_color"]
        @stylesheet = @config["stylesheet"]

        entries = @config["entries"]
          .flat_map { |entry|

            languages.map { |language|

              newEntry = entry.dup

              newEntry["screenshot"] = @imageDirectory + language + entry["screenshot"]
              newEntry["filename"] =  @outputDirectory + language + entry["screenshot"]
              newEntry["locale"] = language

              newEntry
            }
          }
          .sort { |x,y|
            x["screenshot"] <=> y["screenshot"]
          }

        bar = ProgressBar.new(entries.count, :bar, :counter, :eta, :rate)

        Parallel.map(entries, finish: -> (item, i, result) {
          bar.increment!
        }) do |entry|
          device = devices[entry["device"]]

          canvas = canvas_with_device_frame(device, entry)
          canvas = add_caption_to_canvas(entry, canvas, device)
          canvas = draw_screenshot_to_canvas(entry, canvas, device)
          canvas = draw_attachments_to_canvas(entry, canvas)

          # Automatically create intermediate directories for output
          output_filename = resolve_path(entry["filename"])
          dirname = File.dirname(output_filename)
          unless File.directory?(dirname)
            FileUtils.mkdir_p(dirname)
          end

          canvas.write(output_filename)
          canvas.destroy!

          # Run the GC in the same thread to clean up after RMagick
          GC.start
          
        end
      end

      def resolve_path(path)

        current_path = Pathname.new(path)

        if current_path.exist? then
          return current_path
        end

        Pathname.new(FastlaneCore::FastlaneFolder.fastfile_path).dirname + path
      end

      private

      def canvas_with_device_frame(device, entry)

        canvas_size = device["canvas_size"]

        canvas = Image.new(canvas_size[0], canvas_size[1]) {
          self.background_color = background_color
        }

        if entry["background"] != nil
          background_image = resolve_path(entry["background"]).realpath
          background_image = Magick::Image.read(background_image).first
          canvas = canvas.composite(background_image, NorthWestGravity, 0, 0, Magick::OverCompositeOp)
        end

        w = device["device_frame_size"][0]
        h = device["device_frame_size"][1]

        device_frame = resolve_path(device["device_frame"]).realpath
        device_frame = Magick::Image.read(device_frame) {
            self.format = 'SVG'
            self.background_color = 'transparent'
        }.first.adaptive_resize(w, h)

        x = device["device_frame_offset"][0]
        y = device["device_frame_offset"][1]

        canvas.composite(device_frame, NorthWestGravity, x, y, Magick::OverCompositeOp)
      end

      def add_caption_to_canvas(entry, canvas, device)

        text = entry["text"]
        text_size = device["text_size"]
        font_size = device["font_size"]
        locale = entry["locale"]

        # Add the locale to the location string
        localizedFile = sprintf(text, locale)
        if File.exist?(localizedFile)
          text = localizedFile
        elsif File.exist?(resolve_path(localizedFile))
          text = resolve_path(localizedFile).realpath.to_s
        else
          text = sprintf(text, "source")
        end

        width = text_size[0]
        height = text_size[1]

        text_frame = Image.new(width, height) {
          self.background_color = 'transparent'
        }

        stylesheet_path = resolve_path(@stylesheet)
        tempTextFile = Tempfile.new()

        begin

          command = "bundle exec drawText html=" + text + " maxWidth=#{width} maxHeight=#{height} output=#{tempTextFile.path} fontSize=#{font_size} stylesheet=#{stylesheet_path}"

          unless system(command)
            UI.crash!("Unable to draw text")
          end

        text_content = Magick::Image.read(tempTextFile.path) {
          self.background_color = 'transparent'
        }.first

          x = 0
          y = 0

          if device["text_offset"] != nil
              x = device["text_offset"][0]
              y = device["text_offset"][1]
          end

          text_frame.composite!(text_content, CenterGravity, x, y, Magick::OverCompositeOp)

        ensure
          tempTextFile.close
          tempTextFile.unlink
        end

        canvas.composite!(text_frame, NorthGravity, Magick::OverCompositeOp)
      end

      def draw_screenshot_to_canvas(entry, canvas, device)

        device_mask = device["screenshot_mask"]
        screenshot_size = device["screenshot_size"]
        screenshot_offset = device["screenshot_offset"]

        screenshot = entry["screenshot"]

        screenshot = Magick::Image.read(screenshot) {
          self.background_color = 'transparent'
        }
        .first

        if device_mask != nil
          device_mask = resolve_path(device_mask)
          screenshot_mask = Magick::Image.read(device_mask).first
          screenshot = screenshot.composite(screenshot_mask, 0, 0, CopyOpacityCompositeOp)
        end

        screenshot = screenshot.adaptive_resize(screenshot_size[0], screenshot_size[1])

        x_offset = screenshot_offset[0]
        y_offset = screenshot_offset[1]

        canvas.composite(screenshot, NorthWestGravity, x_offset, y_offset, Magick::OverCompositeOp)
      end

      def draw_attachments_to_canvas(entry, canvas)

        entry["attachments"].each { |attachment|

          file = resolve_path(attachment["file"])
          size = attachment["size"]
          position = attachment["position"]

          attachment_image = Magick::Image.read(file) {
            self.background_color = 'transparent'
          }
          .first
          .adaptive_resize(size[0], size[1])

          x = position[0]
          y = position[1]

          canvas.composite!(attachment_image, NorthWestGravity, x, y, Magick::OverCompositeOp)
        }

        canvas
      end
    end
  end
end
