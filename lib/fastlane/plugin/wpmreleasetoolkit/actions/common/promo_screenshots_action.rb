require 'fileutils'
require 'fastlane/action'
require 'active_support/all'
require_relative '../../helper/promo_screenshots_helper.rb'

module Fastlane
  module Actions
    class PromoScreenshotsAction < Action
      def self.run(params)
        UI.message 'Creating Promo Screenshots'
        UI.message "#{self.check_path(params[:orig_folder])} Original Screenshot Source: #{params[:orig_folder]}"
        UI.message "#{self.check_path(params[:metadata_folder])} Translation source: #{params[:metadata_folder]}"

        config = helper.read_json(params[:config_file])

        translationDirectories = subdirectories_for_path(params[:metadata_folder])
        imageDirectories = subdirectories_for_path(params[:orig_folder])

        unless helper.can_resolve_path(params[:output_folder]) then
          UI.message "✅ Created Output Folder: #{params[:output_folder]}"
          FileUtils.mkdir_p(params[:output_folder])
        else
          UI.message "#{self.check_path(params[:output_folder])} Output Folder: #{params[:output_folder]}"
        end

        outputDirectory = helper.resolve_path(params[:output_folder])

        ## If there are no translated screenshot images (whether it's because they haven't been generated yet,
        ##   or because we aren't using them), just use the translated directories.
        languages = if imageDirectories == []
                      translationDirectories
                    ## And vice-versa.
                    elsif translationDirectories == []
                      imageDirectories
                    ## If there are original screenshots and translations available, use only locales that exist in both.
                    else
                      imageDirectories & translationDirectories
                    end

        UI.message("💙 Creating Promo Screenshots for: #{languages.join(", ")}")

        confirm_directory_overwrite(params[:output_folder], 'the existing promo screenshots') unless params[:force]

        # Create a hash of devices, keyed by device name
        devices = config['devices']
        devices = Hash[devices.map { |device| device['name'] }.zip(devices)]

        stylesheet_path = config['stylesheet']

        entries = config['entries']
                  .flat_map do |entry|
                    languages.map do |language|
                      newEntry = entry.deep_dup

                      # Not every output file will have a screenshot, so handle cases where no
                      # screenshot file is defined
                      if entry['screenshot'] != nil && entry['filename'] != nil
                        newEntry['screenshot'] = helper.resolve_path(params[:orig_folder]) + language + entry['screenshot']
                        newEntry['filename'] =  outputDirectory + language + entry['filename']
                      elsif entry['screenshot'] != nil && entry['filename'] == nil
                        newEntry['screenshot'] = helper.resolve_path(params[:orig_folder]) + language + entry['screenshot']
                        newEntry['filename'] =  outputDirectory + language + entry['screenshot']
                      elsif entry['screenshot'] == nil && entry['filename'] != nil
                        newEntry['filename'] =  outputDirectory + language + entry['filename']
                      else
                        puts newEntry
                        abort 'Unable to find output file names'
                      end

                      newEntry['locale'] = language

                      # Localize file paths for text
                      newEntry['text'].sub!('{locale}', language.dup) if entry['text'] != nil

                      # Map attachments paths to their localized versions
                      newEntry['attachments'] = [] if newEntry['attachments'] == nil

                      newEntry['attachments'].each do |attachment|
                        attachment['file'].sub!('{locale}', language.dup) if attachment['file'] != nil

                        attachment['text'].sub!('{locale}', language.dup) if attachment['text'] != nil
                      end

                      newEntry
                    end
                  end
                  .sort do |x, y|
          x['filename'] <=> y['filename']
        end

        bar = ProgressBar.new(entries.count, :bar, :counter, :eta, :rate)

        Parallel.map(entries, finish: ->(_item, _i, _result) {
          bar.increment!
        }) do |entry|
          device = devices[entry['device']]

          UI.message("Unable to find device #{entry["device"]}.") if device == nil

          width = device['canvas_size'][0]
          height = device['canvas_size'][1]

          canvas = helper.create_image(width, height)
          canvas = helper.draw_background_to_canvas(canvas, entry)

          canvas = helper.draw_device_frame_to_canvas(device, canvas)
          canvas = helper.draw_caption_to_canvas(entry, canvas, device, stylesheet_path)
          canvas = helper.draw_screenshot_to_canvas(entry, canvas, device)
          canvas = helper.draw_attachments_to_canvas(entry, canvas)

          # Automatically create intermediate directories for output
          output_filename = entry['filename']
          dirname = File.dirname(output_filename)

          FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

          canvas.write(output_filename)
          canvas.destroy!

          # Run the GC in the same thread to clean up after RMagick
          GC.start
        end
      end

      def self.confirm_directory_overwrite(path, description)
        if (File.exist?(path)) then
          if UI.confirm("Do you want to overwrite #{description}?") then
            FileUtils.rm_rf(path)
            Dir.mkdir(path)
          else
            UI.user_error!("Exiting to avoid overwriting #{description}.")
          end
        else
          Dir.mkdir(path)
        end
      end

      def self.subdirectories_for_path(path)
        subdirectories = []

        return [] unless helper.can_resolve_path(path)

        resolved_path = helper.resolve_path(path)

        Dir.chdir(resolved_path) do
          subdirectories = Dir['*'].select { |o| File.directory?(o) }.sort
        end

        subdirectories
      end

      def self.check_path(path)
        self.helper.can_resolve_path(path) ? '✅' : '🚫'
      end

      def self.helper
        return Fastlane::Helper::PromoScreenshots.new
      end

      def self.description
        'Generate promo screenshots'
      end

      def self.authors
        ['Lorenzo Mattei']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        'Creates promo screenshots starting from standard ones'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :orig_folder,
                                       env_name: 'PROMOSS_ORIG',
                                       description: 'The directory containing the original screenshots',
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :output_folder,
                                       env_name: 'PROMOSS_OUTPUT',
                                       description: 'The path of the folder to save the promo screenshots',
                                       optional: false,
                                       is_string: true),

          FastlaneCore::ConfigItem.new(key: :metadata_folder,
                                       env_name: 'PROMOSS_METADATA_FOLDER',
                                       description: 'The directory containing the translation data',
                                       optional: false,
                                       is_string: true),

          FastlaneCore::ConfigItem.new(key: :config_file,
                                       env_name: 'PROMOSS_CONFIG_FILE',
                                       description: 'The path to the file containing the promo screenshot configuration',
                                       optional: true,
                                       is_string: true,
                                       default_value: 'screenshots.json'),

          FastlaneCore::ConfigItem.new(key: :force,
                                       env_name: 'PROMOSS_FORCE_CREATION',
                                       description: 'Overwrite existing promo screenshots without asking first?',
                                       optional: true,
                                       is_string: false,
                                       default_value: false),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
