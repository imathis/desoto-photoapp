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

        config = {
          'source' => Dir.pwd, # where photos are located
          'url_base' => 'cave.pics',
          'watermark' => Photoapp.gem_dir('assets', 'watermark.png'),
          'font' => Photoapp.gem_dir('assets', "SourceSansPro-Semibold.ttf"),
          'font_size' => 36,
          'date_font_size' => 24,
          'config' => 'photoapp.yml',
          'upload' => 'upload',
          'print' => 'print',
          'import' => 'import',
          'reprint' => 'reprint'
        }
 
        config_file = root(options['config'] || config['config'])

        config['source'] = options['source'] || config['source']

        if File.exist?(config_file)
          config.merge!(YAML.load(File.read(config_file)) || {})
        end

        config['upload']  = root(config['upload'])
        config['print']   = root(config['print'])
        config['import']  = root(config['import'])
        config['reprint'] = root(config['reprint'])

        config
      end

    end

    def logo
      @logo ||= Magick::Image.read(config['watermark']).first
    end

    def process
      photos = load_photos
      tmp = root('.tmp')
      FileUtils.mkdir_p tmp

      photos.map! do |f|
        p = process_image(f, tmp)
        p.write
        p
      end

      import
      print

      FileUtils.rm_rf tmp
    end

    def import
      `automator -i #{config['import']} #{Photoapp.gem_dir("lib/import-photos.workflow")}`
      FileUtils.rm_rf config['import']
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
      `automator -i #{path} #{Photoapp.gem_dir("lib/adjust-image.workflow")}`
      Photo.new(path, logo, self)
    end


    # grab all photos from config source
    def load_photos(path)
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
        status = S3.new(@config).push
        FileUtils.rm photos
        many = photos.size != 1 ? "photos" : "photo"
        puts "Uploaded #{photos.size} #{many}."
      else
        puts "There are no photos to upload."
      end
    end

    def reprint
      files = ['*.jpg', '*.JPG', '*.JPEG', '*.jpeg'].map! { |f| File.join(config['reprint'], f) }
      photos = Dir[*files].uniq
      if !photos.empty?
        system "lpr #{photos.join(' ')}"
        if photos.size == 1
          puts "Printing #{photos.size} photo"
        else
          puts "Printing #{photos.size} photos"
        end
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
      `automator -i #{path} #{Photoapp.gem_dir("lib/adjust-image.workflow")}`

      Photo.new(path, logo, self).write(path)
    end

  end
end
