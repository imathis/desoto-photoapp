require 'RMagick'

module Photoapp
  class Photo
    include Magick
    attr_accessor :file, :logo, :image

    def initialize(file, logo)
      @file = file
      @logo = logo
    end

    def image
      @image || = Magick::Image.read(file).first.resize_to_fill(2100, 1500, NorthGravity)
    end

    def watermark
      @watermarked ||= image.composite(logo, SouthWestGravity, OverCompositeOp)
    end

    def with_url
      @printable ||= add_url(watermark.dup)
    end

    def add_url(image)
      text = Draw.new
      text.annotate(image, 0, 0, 60, 50, "#{Photoapp.config['url_base']}/#{short}.jpg") do
        text.gravity = SouthEastGravity
        text.pointsize = 26
        text.fill = "rgba(255, 255, 255, 0.7)"
        text.font = "SourceSansPro-Semibold.ttf"
        text.stroke = "none"
      end
      image
    end

    def write(dest)
      watermark.write watermark_dest
      with_url.write with_url_dest
      cleanup
    end

    def cleanup
      watermark.destroy!
      with_url.destroy!
    end

    def file_path
      File.expand_path(File.dirname(file))
    end

    def watermark_dest
      File.join(file_path.sub('inbound', 'upload'), short + '.jpg')
    end

    def with_url_dest
      watermark_dest.sub('upload', 'print')
    end

    def short
      @short ||= begin
        source = [*?a..?z] - ['o', 'l'] + [*2..9]
        short = ''
        8.times { short << source.sample.to_s }
        short
      end
    end

  end
end
