require 'tmpdir'
begin
  $skip_magick = false
  require 'RMagick'
rescue LoadError
  $skip_magick = true
end
require 'json'
require 'tempfile'
require 'optparse'
require 'pathname'
require 'progress_bar'
require 'parallel'
require 'jsonlint'
require 'chroma'
require 'securerandom'

include Magick unless $skip_magick

module Fastlane
  module Helper
    class PromoScreenshots

      def initialize(configFilePath, imageDirectory, translationDirectory, outputDirectory)
        if ($skip_magick)
          message = "PromoScreenshots feature is currently disabled.\n"
          message << "Please, install RMagick if you aim to generate the PromoScreenshots.\n"
          message << "\'bundle install --with screenshots\' should do it if your project is configured for PromoScreenshots.\n"
          message << "Aborting."
          UI.user_error!(message)
        end

        @configFilePath = resolve_path(configFilePath)
        @imageDirectory = resolve_path(imageDirectory)
        @translationDirectory = resolve_path(translationDirectory)
        @outputDirectory = resolve_path(outputDirectory)

      def read_json(configFilePath)
        configFilePath = resolve_path(configFilePath)

        begin
          return JSON.parse(open(configFilePath).read)
        rescue
            linter = JsonLint::Linter.new
            linter.check(configFilePath)
            linter.display_errors

            UI.user_error!("Invalid JSON configuration. See errors in log.")
        end
      end

      def draw_caption_to_canvas(entry, canvas, device, stylesheet_path = "")

        # If no caption is provided, it's ok to skip the body of this method
        if entry["text"] == nil
          return canvas
        end

        text = entry["text"]
        text_size = device["text_size"]
        font_size = device["font_size"]
        locale = entry["locale"]

        text = resolve_text_into_path(text, locale)

        if can_resolve_path(stylesheet_path)
          stylesheet_path = resolve_path(stylesheet_path)
        end

        width = text_size[0]
        height = text_size[1]

        x_position = 0
        y_position = 0

        if device["text_offset"] != nil
          x_position = device["text_offset"][0]
          y_position = device["text_offset"][1]
        end

        draw_text_to_canvas(  canvas,
                              text,
                              width,
                              height,
                              x_position,
                              y_position,
                              font_size,
                              stylesheet_path
        )
      end

      def draw_background_to_canvas(canvas, entry)

        if entry["background"] != nil

          # If we're passed an image path, let's open it and paint it to the canvas
          if can_resolve_path(entry["background"])
            background_image = open_image(entry["background"])
            return composite_image(canvas, background_image, 0, 0)
          else  # Otherwise, let's assume this is a colour code
            background_image = create_image(canvas.columns, canvas.rows, entry["background"])
            canvas = composite_image(canvas, background_image, 0, 0)
          end
        end

        canvas
      end

      def draw_device_frame_to_canvas(device, canvas)

        # Apply the device frame to the canvas, but only if one is provided
        unless device["device_frame_size"] != nil
          return canvas
        end

        w = device["device_frame_size"][0]
        h = device["device_frame_size"][1]

        x = 0
        y = 0

        if device["device_frame_size"] != nil
          x = device["device_frame_offset"][0]
          y = device["device_frame_offset"][1]
        end

        device_frame = open_image(device["device_frame"])
        device_frame = resize_image(device_frame, w, h)
        composite_image(canvas, device_frame, x, y)
      end

      def draw_screenshot_to_canvas(entry, canvas, device)

        # Don't require a screenshot to be present – we can just skip
        # this function if one doesn't exist.
        unless entry["screenshot"] != nil
          return canvas
        end

        device_mask = device["screenshot_mask"]
        screenshot_size = device["screenshot_size"]
        screenshot_offset = device["screenshot_offset"]

        screenshot = entry["screenshot"]

        screenshot = open_image(screenshot)

        if device_mask != nil
          screenshot = mask_image(screenshot, open_image(device_mask))
        end

        screenshot = resize_image(screenshot, screenshot_size[0], screenshot_size[1])
        composite_image(canvas, screenshot, screenshot_offset[0], screenshot_offset[1])
      end

      def draw_attachments_to_canvas(entry, canvas)
        
        entry["attachments"].each { |attachment|
          if attachment["file"] != nil
            canvas = draw_file_attachment_to_canvas(attachment, canvas, entry)
          elsif attachment["text"] != nil
            canvas = draw_text_attachment_to_canvas(attachment, canvas, entry["locale"])
          end
        }
        
        return canvas
      end

      def draw_file_attachment_to_canvas(attachment, canvas, entry)

          file = resolve_path(attachment["file"])

          image = open_image(file)

          if attachment.member?("operations")

            attachment["operations"].each { |operation|
              image = apply_operation(image, operation, canvas)
            }

            image.write("after-image.png")
          end

          size = attachment["size"]

          x_pos = attachment["position"][0]
          y_pos = attachment["position"][1]

          if attachment["offset"] != nil
            x_pos += attachment["offset"][0]
            y_pos += attachment["offset"][1]
          end

          image = resize_image(image, size[0], size[1])
          canvas = composite_image(canvas, image, x_pos, y_pos)
      end

      def draw_text_attachment_to_canvas(attachment, canvas, locale)

        text = resolve_text_into_path(attachment["text"], locale)
        font_size = attachment["font-size"] ||= 12

        width  = attachment["size"][0]
        height = attachment["size"][1]

        x_position = attachment["position"][0] ||= 0
        y_position = attachment["position"][1] ||= 0

        stylesheet_path = attachment["stylesheet"]
        if can_resolve_path(stylesheet_path)
          stylesheet_path = resolve_path(stylesheet_path)
        end

        draw_text_to_canvas(  canvas,
                              text,
                              width,
                              height,
                              x_position,
                              y_position,
                              font_size,
                              stylesheet_path
        )
      end

      def apply_operation(image, operation, canvas)
      
        return case operation["type"]
          when "crop"
            x_pos = operation["at"][0]
            y_pos = operation["at"][1]

            width = operation["to"][0]
            height = operation["to"][1]

            crop_image(image, x_pos, y_pos, width, height)

          when "resize"
            width = operation["to"][0]
            height = operation["to"][1]

            resize_image(image, width, height)

          when "composite"

            x_pos = operation["at"][0]
            y_pos = operation["at"][1]

            if operation.member?("offset")
              x_pos += operation["offset"][0]
              y_pos += operation["offset"][1]
            end

            composite_image(canvas, image, x_pos, y_pos)
          end
      end

      def draw_text_to_canvas(canvas, text, width, height, x_position, y_position, font_size, stylesheet_path, position = 'center')
        begin
          
          tempTextFile = Tempfile.new()

          command = "bundle exec drawText html=\"#{text}\" maxWidth=#{width} maxHeight=#{height} output=#{tempTextFile.path} fontSize=#{font_size} stylesheet=\"#{stylesheet_path}\""

          unless system(command)
            UI.crash!("Unable to draw text")
          end

          text_content = open_image(tempTextFile.path)
          text_frame = create_image(width, height)
          text_frame = case position
            when 'center' then composite_image_center(text_frame, text_content, 0, 0)
            when 'top' then composite_image_top(text_frame, text_content, 0, 0)
            end
        ensure
          tempTextFile.close
          tempTextFile.unlink
        end

        composite_image(canvas, text_frame, x_position, y_position)
      end

      # mask_image
      #
      # @example
      #
      #.  image = open_image("image-path")
      #.  mask  = open_image("mask-path")
      #
      #   mask_image(image, mask)
      #
      # @param [Magick::Image] image An ImageMagick object containing the image to be masked.
      # @param [Magick::Image] mask An ImageMagick object containing the mask to be be applied.
      #
      # @return [Magick::Image] The masked image
      def mask_image(image, mask, offset_x = 0, offset_y = 0)
          image.composite(mask, offset_x, offset_y, CopyAlphaCompositeOp)
      end

      # resize_image
      #
      # @example
      #
      #.  image = open_image("image-path")
      #   resize_image(image, 640, 480)
      #
      # @param [Magick::Image] original An ImageMagick object containing the image to be masked.
      # @param [Integer] width The new width for the image.
      # @param [Integer] height The new height for the image.
      #
      # @return [Magick::Image] The resized image
      def resize_image(original, width, height)

        if !original.is_a?(Magick::Image)
          UI.user_error!("You must pass an image object to `resize_image`.")
        end

        original.adaptive_resize(width, height)
      end

      # composite_image
      #
      # @example
      #
      #.  image = open_image("image-path")
      #.  other = open_image("other-path")
      #   composite_image(image, other, 0, 0)
      #
      # @param [Magick::Image] image The original image.
      # @param [Magick::Image] image The image that will be placed onto the original image.
      # @param [Integer] x_position The horizontal position for the image to be placed.
      # @param [Integer] y_position The vertical position for the image to be placed.
      #
      # @return [Magick::Image] The resized image
      def composite_image(original, child, x_position, y_position, starting_position = NorthWestGravity)

        if !original.is_a?(Magick::Image)
          UI.user_error!("You must pass an image object as the first argument to `composite_image`.")
        end

        if !child.is_a?(Magick::Image)
          UI.user_error!("You must pass an image object as the second argument to `composite_image`.")
        end

        original.composite(child, starting_position, x_position, y_position, Magick::OverCompositeOp)
      end

      def composite_image_top(original, child, x_position, y_position)
        composite_image(original, child, x_position, y_position, NorthGravity)
      end


      def composite_image_center(original, child, x_position, y_position)
        composite_image(original, child, x_position, y_position, CenterGravity)
      end

      # crop_image
      #
      # @example
      #
      #.  image = open_image("image-path")
      #   crop_image(image, other, 0, 0)
      #
      # @param [Magick::Image] original The original image.
      # @param [Integer] x_position The horizontal position to start cropping from.
      # @param [Integer] y_position The vertical position to start cropping from.
      # @param [Integer] width The width of the final image.
      # @param [Integer] height The height of the final image.
      #
      # @return [Magick::Image] The resized image
      def crop_image(original, x_position, y_position, width, height)
        
        if !original.is_a?(Magick::Image)
          UI.user_error!("You must pass an image object to `crop_image`.")
        end

        original.crop(x_position, y_position, width, height)
      end

      def open_image(path)
          path = resolve_path(path)

          Magick::Image.read(path)  {
            self.background_color = 'transparent'
          }.first
      end

      def create_image(width, height, background = 'transparent')

        background_color = background.paint.to_hex

        Image.new(width, height) {
          self.background_color = background
        }
      end

      def can_resolve_path(path)
        begin
          resolve_path(path)
          return true
        rescue
          return false
        end
      end

      def resolve_path(path)

        if path == nil
          UI.crash!("Path not provided – you must provide one to continue")
        end

        [
          Pathname.new(path),                                                           # Absolute Path
          Pathname.new(FastlaneCore::FastlaneFolder.fastfile_path).dirname + path,      # Path Relative to the fastfile
          Fastlane::Helper::FilesystemHelper.plugin_root + path,                        # Path Relative to the plugin
          Fastlane::Helper::FilesystemHelper.plugin_root + "spec/test-data/" + path,    # Path Relative to the test data
        ]
        .each { |resolved_path| 

          if resolved_path != nil && resolved_path.exist?
            return resolved_path
          end
        }

        message = "Unable to locate #{path}"
        UI.crash!(message)
      end

      def resolve_text_into_path(text, locale)

        localizedFile = sprintf(text, locale)

        if File.exist?(localizedFile)
          text = localizedFile
        elsif can_resolve_path(localizedFile)
          text = resolve_path(localizedFile).realpath.to_s
        else
          text = sprintf(text, "source")
        end
      end
    end
  end
end
