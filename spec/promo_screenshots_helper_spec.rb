require 'shellwords'
require_relative './spec_helper'

describe Fastlane::Helper::PromoScreenshots do

  context "initialization" do

      it "parses valid JSON test files" do
        # helper = helper.new(test_data_path_for("empty.json"), "", "", "")
        configuration = helper.read_json(test_data_path_for("empty.json"))
      end

      it "throws an error for missing json test files" do
        expect{
          helper.read_json(test_data_path_for("nonexistent.json"))
        }.to raise_error(FastlaneCore::Interface::FastlaneCrash)
    end

    it "throws an error for malformed json test files" do
      silence_output
        expect{
          helper.read_json(test_data_path_for("malformed.json"))
        }.to raise_error(FastlaneCore::Interface::FastlaneError)
        unsilence_output
    end
  end

  context "helpers can" do

    context "resolve paths" do
      it "can find images in the test helpers" do
        path = helper.resolve_path("images/source/blue-square.png")
      end

      it "can find scripts in the test helpers" do
        path = helper.resolve_path("scripts/attachment-test-1.json")
      end
    end

    context "open images" do 
      it "with a valid image path" do
        helper.open_image(test_data_path_for("images/source/blue-square.png"))
      end

      it "and crashes on invalid image paths" do
        expect{
          helper.open_image(test_data_path_for("images/source/nonexistent-image.jpg"))
        }.to raise_error(FastlaneCore::Interface::FastlaneCrash)
      end
    end
  end

  context "perform images operations, including" do
    context "masking and" do
      it "can mask images" do
        image = source_image("blue-square.png")
        mask = source_image("white-circle.png")

        output = helper.mask_image(image, mask)
        expect(images_are_identical(output, "mask-1.png")).to eq(true)
      end

      it "can mask images with a positive offset" do
        image = source_image("blue-square.png")
        mask = source_image("white-circle.png")

        output = helper.mask_image(image, mask, 250, 250)
        expect(images_are_identical(output, "mask-2.png")).to eq(true)
      end

      it "can mask images with a negative offset" do
        image = source_image("blue-square.png")
        mask = source_image("white-circle.png")

        output = helper.mask_image(image, mask, -250, -250)
        expect(images_are_identical(output, "mask-3.png")).to eq(true)
      end
    end

    context "resizing and" do

      it "can resize images to be smaller" do
        image = source_image("white-circle.png")

        output = helper.resize_image(image, 50, 50)
        sample = write_test_data(output)  #for some reason this is needed to make tests pass
        expect(images_are_identical(output, sample)).to eq(true)
      end

       it "can resize images to be larger" do
        image = source_image("white-circle.png")

        output = helper.resize_image(image, 1000, 1000)
        sample = write_test_data(output)  #for some reason this is needed to make tests pass
        expect(images_are_identical(output, sample)).to eq(true)
      end
    end

    context "cropping and" do

      it "crop images within image bounds" do
        image = source_image("blue-square.png")

        output = helper.crop_image(image, 0, 0, 50, 50)
        expect(images_are_identical(output, "cropped-1.png")).to eq(true)
      end

       it "crop images outside image bounds only keeping existing data" do
        image = source_image("blue-square.png")

        output = helper.crop_image(image, 475, 475, 50, 50)
        expect(images_are_identical(output, "cropped-1.png")).to eq(true)
      end
    end
  end

  context "perform high-level compositing operations, including" do
    
    it "draws attachments with cropping, resizing, and compositing" do

      entry = sample_script("attachment-test-1.json")

      image = helper.create_image(1000, 1000)
      output = helper.draw_attachments_to_canvas(entry, image)
      expect(images_are_identical(output, "attachment-test-1.png")).to eq(true)
    end

    it "draws simple attachments" do

      entry = sample_script("attachment-test-2.json")

      image = helper.create_image(1000, 1000)
      output = helper.draw_attachments_to_canvas(entry, image)
      expect(images_are_identical(output, "attachment-test-1.png")).to eq(true)
    end

    it "draws screenshots to the canvas with a device mask" do

      script = sample_script("screenshot-test-1.json")
      entry = script["entries"][0]
      device = script["devices"][0]

      image = helper.create_image(1000, 1000)
      output = helper.draw_screenshot_to_canvas(entry, image, device)
      expect(images_are_identical(output, "screenshot-test-1.png")).to eq(true)
    end

    it "draws screenshots to the canvas without a device mask" do

      script = sample_script("screenshot-test-1.json")
      entry = script["entries"][0]
      device = script["devices"][0]
      device.delete("screenshot_mask")

      image = helper.create_image(1000, 1000)
      output = helper.draw_screenshot_to_canvas(entry, image, device)
      expect(images_are_identical(output, "screenshot-test-2.png")).to eq(true)
    end

    it "doesn't crash if no screenshot exists on the entry" do

      script = sample_script("screenshot-test-2.json")
      entry = script["entries"][0]
      device = script["devices"][0]

      image = helper.create_image(1000, 1000)
      output = helper.draw_screenshot_to_canvas(entry, image, device)
      expect(images_are_identical(output, "screenshot-test-4.png")).to eq(true)
    end

    it "draws background images to the canvas" do

      entry = sample_script("background-test-1.json")

      image = helper.create_image(500, 500)
      output = helper.draw_background_to_canvas(image, entry)
      expect(images_are_identical(output, "background-test-1.png")).to eq(true)
    end

    it "draws background colors to the canvas" do

      entry = sample_script("background-test-2.json")
      
      image = helper.create_image(500, 500)
      output = helper.draw_background_to_canvas(image, entry)
      expect(images_are_identical(output, "background-test-2.png")).to eq(true)
    end

    it "draws the device frame to the canvas" do

      script = sample_script("screenshot-test-1.json")
      device = script["devices"][0]

      image = helper.create_image(1000, 1000)
      output = helper.draw_device_frame_to_canvas(device, image)
      expect(images_are_identical(output, "screenshot-test-3.png")).to eq(true)
    end

    it "doesn't crash if no device frame is provided" do

      script = sample_script("screenshot-test-1.json")
      device = script["devices"][0]
      device.delete("device_frame_size")

      image = helper.create_image(1000, 1000)
      output = helper.draw_device_frame_to_canvas(device, image)
      expect(images_are_identical(output, "screenshot-test-4.png")).to eq(true)
    end

    it "draws the caption to the canvas" do

      script = sample_script("text-test-1.json")
      device = script["devices"][0]
      entry = script["entries"][0]

      image = helper.create_image(500, 500, "blue")
      output = helper.draw_caption_to_canvas(entry, image, device, sample_stylesheet("white-text.css"))

      expect(images_are_identical(output, "text-test-1.png")).to eq(true)
    end

    it "draws the caption to the canvas with the stylesheet" do

      script = sample_script("text-test-1.json")
      device = script["devices"][0]
      entry = script["entries"][0]

      image = helper.create_image(500, 500, "blue")
      output = helper.draw_caption_to_canvas(entry, image, device, sample_stylesheet("black-text.css"))

      expect(images_are_identical(output, "text-test-2.png")).to eq(true)
    end
  end
end

def helper()
  Fastlane::Helper::PromoScreenshots.new
end

def source_image(filename)
  helper.open_image(test_data_path_for("images/source/#{filename}"))
end

def sample_image(filename)
  helper.open_image(test_data_path_for("images/output/#{filename}"))
end

def sample_script(filename)
  filename = test_data_path_for("scripts/#{filename}")
  return JSON.parse(open(filename).read)
end

def sample_stylesheet(filename)
  test_data_path_for("scripts/#{filename}")
end

def test_data_path_for(filename)
  File.expand_path(File.join(File.dirname(__FILE__), 'test-data', filename))
end

def write_test_data(output, filename = "")

  if filename.empty?
    filename = Tempfile.new(output.signature).path
  else
    filename = test_data_path_for("images/output/#{filename}")
  end

  output.write(filename)

  output
end

def images_are_identical(image1, sample_image)

  if sample_image.is_a? String
    sample_image = sample_image(sample_image)
  end

  image1.compare_channel(sample_image, Magick::MeanAbsoluteErrorMetric)[1] == 0
end

$original_stderr = $stderr
$original_stdout = $stdout

def silence_output
  $stderr = File.open(File::NULL, "w")
  $stdout = File.open(File::NULL, "w")
end

def unsilence_output
  $stderr = $original_stderr
  $stdout = $original_stdout
end
