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
          'url_base' => 'www.cave.pics',
          'watermark' => Photoapp.gem_dir('assets', 'watermark.png'),
          'font' => Photoapp.gem_dir('assets', "SourceSansPro-Semibold.ttf"),
          'font_size' => 30,
          'config' => 'photoapp.yml',
          'upload' => 'upload',
          'print' => 'print',
          'reprint' => 'reprint'
        }
 
        config_file = root(options['config'] || config['config'])

        config['source'] = options['source'] || config['source']

        if File.exist?(config_file)
          config.merge!(YAML.load(File.read(config_file)) || {})
        end

        config['upload'] = root(config['upload'])
        config['print'] = root(config['print'])
        config['reprint'] = root(config['reprint'])

        config
      end

    end

    def logo
      @logo ||= Magick::Image.read(config['watermark']).first
    end

    def process
      photos = []
      tmp = root('.tmp')
      import = root('.import/')
      FileUtils.mkdir_p tmp
      FileUtils.mkdir_p import

      if empty_print_queue?
        FileUtils.rm_rf(config['print'])
      end

      load_photos.each do |f|
        photos << process_image(f, tmp)
      end

      photos.each do |p|
        p.write
        FileUtils.cp p.print_dest, import
        Photoapp.print(p.print_dest)
      end

      `automator -i #{import} #{Photoapp.gem_dir("lib/import-photos.workflow")}`

      upload

      FileUtils.rm_rf tmp
      FileUtils.rm_rf import
    end

    def process_image(photo, destination)
      path = File.join(destination, File.basename(photo))
      FileUtils.mv photo, path
      `automator -i #{path} #{Photoapp.gem_dir("lib/adjust-image.workflow")}`
      Photo.new(path, logo, self)
    end


    def load_photos
      files = ['*.jpg', '*.JPG', '*.JPEG', '*.jpeg'].map! { |f| File.join(config['source'], f) }

      Dir[*files].uniq
    end

    def empty_print_queue?
      if printer = `lpstat -d`
        if printer = printer.scan(/:\s*(.+)/).flatten.first
          `lpstat -o -P #{printer}`.strip == ''
        end
      end
    end

    def upload
      S3.new(@config).push
      FileUtils.rm_rf config['upload']
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
