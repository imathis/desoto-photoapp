require "desoto-photoapp/version"
require "desoto-photoapp/photo"
require "desoto-photoapp/s3"
require 'yaml'
require 'colorator'

module Photoapp
  extend self

  def gem_dir(*paths)
    File.expand_path(File.join(File.dirname(__FILE__), '..', *paths))
  end

  class Session
    attr_accessor :photos, :print, :upload

    ROOT = File.expand_path('~/cave.pics') # where photos are stored

    # relative to root
    CONFIG_FILE = 'photoapp.yml'
    UPLOAD = 'upload'
    PRINT = 'print'


    def initialize(options={})
      @photos = []
      @config = config(options)
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
          'print' => 'print'
        }
 
        config_file = root(options['config'] || config['config'])

        config['source'] = options['source'] || config['source']

        if File.exist?(config_file)
          config.merge!(YAML.load(File.read(config_file)) || {})
        end

        config['upload'] = root(config['upload'])
        config['print'] = root(config['print'])

        config
      end

    end

    def root(path='')
      File.expand_path(File.join(ROOT, path))
    end

    def process
      logo = Magick::Image.read(config['watermark']).first
      photos = []
      tmp = root('.tmp')
      FileUtils.mkdir_p tmp

      if empty_print_queue?
        FileUtils.rm_rf(config['print'])
      end

      load_photos.each do |f|
        path = File.join(tmp, File.basename(f))
        FileUtils.mv f, path
        `automator -i #{path} #{Photoapp.gem_dir("lib/adjust-image.workflow")}`
        photos << Photo.new(path, logo, self)
      end

      photos.each do |p|
        p.write
        p.add_to_photos
        p.print
      end

      FileUtils.rm_rf tmp
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
  end
end
