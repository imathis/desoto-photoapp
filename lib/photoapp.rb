require "photoapp/version"
require "photoapp/config"
require "photoapp/process"

require 'fileUtils'

module Photoapp
  extend self

  CONFIG = {
    'url_base' => 'cave.pics',
    'path_base' => File.expand_path(Dir.pwd),
    'source' => 'inbound'
  }

  def config(options={})
    @config ||= CONFIG.merge(options)
  end

  def process
    logo = Magick::Image.read('watermark.png').first

    Dir["#{config['source']}/*.*"].each do |f|
      photos << Photo.new(f, logo)
    end
  end
end
