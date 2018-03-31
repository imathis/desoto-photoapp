require "photoapp/version"
require "photoapp/photo"
require "photoapp/s3"
require 'yaml'
require 'colorator'

module Photoapp
  extend self

  def gem_dir(*paths)
    File.expand_path(File.join(File.dirname(__FILE__), '..', *paths))
  end

  # Handle printing
  def print(path)
    system "lpr #{path}"
  end

  class Session
    attr_accessor :photos, :print, :upload

    # relative to root
    CONFIG_FILE = 'photoapp.yml'
    UPLOAD = 'upload'
    PRINT = 'print'
    ROOT = File.expand_path('~/cave.pics') # where photos are stored


    def initialize(options={})
      @photos = []
      @config = config(options)
      FileUtils.mkdir_p(config['reprint'])
    end

    def root(path='')
      File.expand_path(File.join(ROOT, path))
    end

    def config(options={})
      @config || begin

        options['source'] ||= root('import')

        config = {
          'source' => Dir.pwd, # where photos are located
          'url_base' => 'cave.pics',
          'watermark' => Photoapp.gem_dir('assets', 'watermark.png'),
          'font' => Photoapp.gem_dir('assets', "SourceSansPro-Semibold.ttf"),
          'font_size' => 36,
          'date_font_size' => 24,
          'config' => 'photoapp.yml',
          'upload' => 'upload',
          'upload_queue' => 'upload_queue',
          'print' => 'print',
          'print_duplicate' => false,
          'photos_import' => 'photos_import',
          'import_alt' => false,
          'reprint' => 'reprint',
          'interval' => 60
        }
 
        config_file = root(options['config'] || config['config'])

        config['source'] = options['source'] || config['source']

        if File.exist?(config_file)
          config.merge!(YAML.load(File.read(config_file)) || {})
        end

        config['upload']  = root(config['upload'])
        config['upload_queue']  = root(config['upload_queue'])
        config['print']   = root(config['print'])
        config['photos_import']  = root(config['photos_import'])
        config['reprint'] = root(config['reprint'])
        config['import_alt'] = File.expand_path(config['import_alt']) if config['import_alt']
        config['print_duplicate'] = File.expand_path(config['print_duplicate']) if config['print_duplicate']

        config
      end

    end

    def logo
      @logo ||= Magick::Image.read(config['watermark']).first
    end

    def process

      photos = load_photos
      unless photos.empty?

        # Announce photos
        noun = photos.size == 1 ? "photo" : "photos"
        system "say -v 'Daniel' 'processing #{photos.size} #{noun}'"

        tmp = root('.tmp')
        FileUtils.mkdir_p tmp

        photos.map! do |f|
          p = process_image(f, tmp)
          p.write
          p
        end

        optimize

        import
        print

        FileUtils.rm_rf tmp
      end
    end

    def import_alt
      import(config['import_alt']) if config['import_alt']
    end

    # Import to Photos.app via AppleScript
    def import(path=nil)
      path ||= config['photos_import']
      script = %Q{osascript -e 'set filePosixPath to "#{path}"
set importFolder to (POSIX file filePosixPath) as alias

set extensionsList to {"jpg", "jpeg"}
tell application "Finder" to set theFiles to every file of importFolder whose name extension is in extensionsList

if (count of theFiles) > 0 then
  set imageList to {}
  repeat with i from 1 to number of items in theFiles
    set this_item to item i of theFiles as alias
    set the end of imageList to this_item
  end repeat

  tell application "Photos"
      activate
      delay 1
      import imageList skip check duplicates yes
  end tell
end if'}
      `#{script}`
      FileUtils.rm load_photos(config['photos_import'])
    end

    def print
      load_photos(config['print']).each do |p|
        system "lpr #{p}"
      end
      FileUtils.rm_rf config['print']
    end

    def process_image(photo, destination)
      path = File.join(destination, File.basename(photo))
      FileUtils.mv photo, path
      Photo.new(path, logo, self)
    end

    def optimize(path=nil)
      path ||= config['upload']
      exec = Photoapp.gem_dir("bin/imageOptim")

      if File.directory?(path)
        `#{exec} -d #{path}`
      else
        `find #{path} | #{exec}`
      end
    end

    # grab all photos from config source
    def load_photos(path=nil)
      path ||= config['source']
      files = ['*.jpg', '*.JPG', '*.JPEG', '*.jpeg'].map! { |f| File.join(path, f) }

      Dir[*files].uniq
    end

    # Check to see if the print queue is empty
    def empty_print_queue?
      if printer = `lpstat -d`
        if printer = printer.scan(/:\s*(.+)/).flatten.first
          `lpstat -o -P #{printer}`.strip == ''
        end
      end
    end

    def upload
      photos = load_photos(config['upload'])

      if photos.size > 0
        FileUtils.mkdir_p config['upload_queue']
        FileUtils.mv photos, config['upload_queue']
        
        status = S3.new(@config).push
        FileUtils.rm_rf config['upload_queue']

        many = photos.size != 1 ? "photos" : "photo"
        system "say -v 'Daniel' 'Uploaded #{photos.size} #{many}.'"
      end
    end

    def reprint
      files = ['*.jpg', '*.JPG', '*.JPEG', '*.jpeg'].map! { |f| File.join(config['reprint'], f) }
      photos = Dir[*files].uniq
      if !photos.empty?
        system "lpr #{photos.join(' ')}"
        count = photos.size == 1 ? "photo" : "photos"
        puts "Printing #{photos.size} #{count}"
      else
        puts "No photos to print"
      end

      sleep 4
      FileUtils.rm(photos)
    end

    # For processing a single image for testing purposes
    #
    def test_image(photo)
      photo = File.expand_path(photo)
      path = photo.sub(/\.jpe?g/i, '.copy.jpg')
      FileUtils.cp photo, path

      Photo.new(path, logo, self).write(path)
      optimize path
    end

    def plist
      %Q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>KeepAlive</key>
    <dict>
      <key>SuccessfulExit</key>
      <false/>
    </dict>
    <key>Label</key>
    <string>com.desotocaverns.photoapp</string>
    <key>ProgramArguments</key>
    <array>
      <string>#{Photoapp.gem_dir('bin', 'process.sh')}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>#{root}</string>
    <key>StartInterval</key>
    <integer>#{config['interval']}</integer>
  </dict>
</plist>}
    end

  end
end
