require "photoapp/version"
require "photoapp/photo"
require "safe_yaml"

module Photoapp
  extend self

  @photos = []

  def config(options={})
    @config ||= begin 
      config = {
        'url_base' => 'cave.pics',
        'source' => Dir.pwd,
        'watermark' => gem_dir('assets', 'watermark.png'),
        'font' => gem_dir('assets', "SourceSansPro-Semibold.ttf"),
        'font_size' => 30
      }.merge(options)

      config['print_dir'] ||= File.join(config['source'], 'print')
      config['upload_dir'] ||= File.join(config['source'], 'upload')

      config
    end
  end

  def load_config(file)
    if File.exist?(file)
      config(SafeYaml.load_file(file) || {})
    end
  end

  def gem_dir(*paths)
    File.expand_path(File.join(File.dirname(__FILE__), '..', *paths))
  end

  def process(options={})
    if options['config']
      Photoapp.load_config(options['config'])
    end

    if options['source'] && File.exist?(options['source'])
      @config['source'] = path
    end

    edit_photos
  end

  def edit_photos
    logo = Magick::Image.read(config['watermark']).first
    tmp = File.join(config['source'], '.tmp')
    FileUtils.mkdir_p(tmp)

    load_photos.each do |f|
      FileUtils.cp f, tmp
      path = File.join(tmp, File.basename(f))
      `automator -i #{path} #{gem_dir("exe/adjust-image.workflow")}`
      @photos << Photo.new(path, logo)
    end

    @photos.each do |p|
      p.write
      FileUtils.rm_rf tmp
    end
  end

  def load_photos
    Dir[File.join(config['source'], 'inbound', "*.*")]
  end
end
