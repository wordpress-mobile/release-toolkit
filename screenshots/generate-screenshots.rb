#!/usr/bin/env ruby

require 'RMagick'
require 'json'
require 'tempfile'
require 'optparse'
require 'pathname'

include Magick

def canvas_with_device_frame(device, background_color)

    canvas_size = device["canvas_size"]

    canvas = Image.new(canvas_size[0], canvas_size[1]) {
        self.background_color = background_color
    }

    w = device["device_frame_size"][0]
    h = device["device_frame_size"][1]

    device_frame = Magick::Image.read(device["device_frame"]) {
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
    if File.exists?(localizedFile)
        text = localizedFile
    else
        text = sprintf(text, "source")
    end

    width = text_size[0]
    height = text_size[1]

    text_frame = Image.new(width, height) {
        self.background_color = 'transparent'
    }

    tempTextFile = Tempfile.new()

    begin

        unless system("./drawText.swift html=" + text + " maxWidth=#{width} maxHeight=#{height} output=#{tempTextFile.path} fontSize=#{font_size} stylesheet=resources/style.css")
            abort()
        end

        text_content = Magick::Image.read(tempTextFile.path) {
            self.background_color = 'transparent'
        }.first

        text_frame.composite!(text_content, CenterGravity, Magick::OverCompositeOp)

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
        screenshot_mask = Magick::Image.read(device_mask).first
        screenshot = screenshot.composite(screenshot_mask, 0, 0, CopyOpacityCompositeOp)
    end

    screenshot = screenshot.adaptive_resize(screenshot_size[0], screenshot_size[1])

    x_offset = screenshot_offset[0]
    y_offset = screenshot_offset[1]

    canvas.composite(screenshot, NorthWestGravity, x_offset, y_offset, Magick::OverCompositeOp)
end

def draw_attachments_to_canvas(entry, canvas, shadowOffset)

    entry["attachments"].each { |attachment|

        file = attachment["file"]

        # Resize the images with extra size to account for the shadows
        size = attachment["size"].map{ |i| i + (shadowOffset * 2) }

        # Correct for the shadow offset by centering the image within the shadow bounds
        position = attachment["position"].map{ |i| i - shadowOffset }

        attachment_image = Magick::Image.read(file) {
            self.background_color = 'transparent'
        }
        .first
        .adaptive_resize(size[0], size[1])

        x = position[0]
        y = position[1]

        canvas.composite!(attachment_image, NorthWestGravity, x, y, Magick::OverCompositeOp)
    }

    return canvas
end

begin
    config = JSON.parse(open("screenshots.json").read)
rescue
    abort("Invalid JSON configuration")
end

options = {}
OptionParser.new do |parser|
    parser.banner = "Usage: generate-screenshots [options]"

    parser.on("--translationsDirectory [METADATADIRECTORY]") do |v|
        options[:translationsDir] = v
    end

    parser.on("--imageSourceDirectory [BASEDIRECTORY]") do |v|
        options[:image_dir] = v
    end
end.parse!

if options[:image_dir] == nil
    abort("You need to specify --imageSourceDirectory")
end

if !File.directory?(options[:image_dir])
    abort("The directory #{options[:base_dir]} does not exist")
end

# Define input and output constants
BASE_DIR = Pathname.new(options[:image_dir])
LANG_DIR = Pathname.new(options[:translationsDir])
OUTPUT_DIR = Pathname.new(Dir.pwd) + "output"

# Determine which languages we're going to generate screenshots
imageDirectories = []
Dir.chdir(BASE_DIR) do
    imageDirectories = Dir["*"].reject{|o| not File.directory?(o)}.sort
end

translationDirectories = []
Dir.chdir(LANG_DIR) do
    translationDirectories = Dir["*"].reject{|o| not File.directory?(o)}.sort
end

languages = imageDirectories & translationDirectories

# Create a hash of devices, keyed by device name
devices = config["devices"]
devices = Hash[devices.map { |device| device["name"] }.zip(devices)]

# Move global settings from the configuration into variables
global_background_color = config["background_color"]
global_shadow_offset = config["shadow_offset"]

config["entries"]
.flat_map { |entry|

    languages.map { |language|


        newEntry = entry.dup

        newEntry["screenshot"] = BASE_DIR + language + entry["screenshot"]
        newEntry["filename"] =  OUTPUT_DIR + language + entry["screenshot"]
        newEntry["locale"] = language

        newEntry
    }
}
.each{ |entry|

    device = devices[entry["device"]]

    canvas = canvas_with_device_frame(device, global_background_color)
    canvas = add_caption_to_canvas(entry, canvas, device)
    canvas = draw_screenshot_to_canvas(entry, canvas, device)
    canvas = draw_attachments_to_canvas(entry, canvas, global_shadow_offset)

    # Automatically create intermediate directories for output
    dirname = File.dirname(entry["filename"])
    unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
    end

    canvas.write(entry["filename"])
}
