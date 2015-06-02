require 'RMagick'

module Photoapp
  class Photo
    include Magick
    attr_accessor :file, :logo, :image, :config, :session

    def initialize(file, logo, session)
      @file = file
      @logo = logo
      @session = session
      @config = session.config
    end

    def config
      @config
    end

    def image
      @image ||= Image.read(file).first.resize_to_fill(2100, 1500, NorthGravity)
    end

    def watermark
      @watermarked ||= image.composite(logo, SouthWestGravity, OverCompositeOp)
    end

    def with_url
      @printable ||= begin
        light_url = add_url("#fff")
        dark_url  = add_url("#000", true).blur_image(radius=6.0, sigma=2.0)
        watermark.dup
          .composite(dark_url, SouthEastGravity, OverCompositeOp)
          .composite(light_url, SouthEastGravity, OverCompositeOp)
      end
    end

    def add_url(color, stroke=false)
      setting = config
      image = Image.new(400,100) { self.background_color = "rgba(255, 255, 255, 0)" }
      text = Draw.new
      text.annotate(image, 0, 0, 60, 50, "#{setting['url_base']}/#{short}.jpg") do
        text.gravity = SouthEastGravity
        text.pointsize = setting['font_size']
        text.fill = color
        text.font = setting['font']
        if stroke
          text.stroke = color
        end
      end
      image
    end

    def write
      FileUtils.mkdir_p(File.dirname(watermark_dest))
      FileUtils.mkdir_p(File.dirname(with_url_dest))
      watermark.write watermark_dest
      with_url.write with_url_dest
      cleanup
    end

    def cleanup
      watermark.destroy!
      with_url.destroy!
    end

    def watermark_dest
      File.join(config['upload_dir'], short + '.jpg')
    end

    def with_url_dest
      File.join(config['print_dir'], short + '.jpg')
    end

    def short
      @short ||= begin
        source = [*?a..?z] - ['o', 'l'] + [*2..9]
        short = ''
        8.times { short << source.sample.to_s }
        session.photos << short + '.jpg'
      end
    end

  end
end
