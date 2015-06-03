require "photoapp/version"
require "photoapp/photo"
require "photoapp/s3"
require 'yaml'
require 'colorator'

module Photoapp
  class Session
    attr_accessor :photos

    def initialize(options={})
      @photos = []
      @config = config(options)

      if options['source'] && File.exist?(options['source'])
        @config['source'] = path
      end
    end

    def config(options={})
      @config || begin 
        c = {
          'config' => 'photoapp.yml',
          'url_base' => 'cave.pics',
          'source' => Dir.pwd,
          'watermark' => gem_dir('assets', 'watermark.png'),
          'font' => gem_dir('assets', "SourceSansPro-Semibold.ttf"),
          'font_size' => 30
        }
        
        if File.exist?(c['config'])
          c = c.merge(YAML.load(File.read(c['config'])) || {})
        end

        c['print_dir'] ||= File.join(c['source'], 'print')
        c['upload_dir'] ||= File.join(c['source'], 'upload')

        c
      end
    end

    def gem_dir(*paths)
      File.expand_path(File.join(File.dirname(__FILE__), '..', *paths))
    end

    def source(path='')
      File.join(config['source'], path)
    end

    def process
      logo = Magick::Image.read(config['watermark']).first
      photos = []
      tmp = source('.tmp')
      FileUtils.mkdir_p(tmp)

      if empty_print_queue?
        FileUtils.rm_rf(config['print_dir'])
      end

      load_photos.each do |f|
        FileUtils.mv f, tmp
        path = File.join(tmp, File.basename(f))
        `automator -i #{path} #{gem_dir("exe/adjust-image.workflow")}`
        photos << Photo.new(path, logo, self)
      end

      photos.each do |p|
        p.write
        #p.print
        FileUtils.rm_rf tmp
      end
    end

    def load_photos
      files = ['*.jpg', '*.JPG', '*.JPEG', '*.jpeg'].map! { |f| File.join(source('inbound'), f) }
      Dir[*files]
    end

    def empty_print_queue?
      if printer = `lpstat -d`
        printer = printer.scan(/:\s*(.+)/).flatten.first.strip
        `lpstat -o -P #{printer}`.strip == ''
      end
    end

    def upload
      S3.new(@config).push
      FileUtils.rm_rf config['upload_dir']
    end
  end
end
