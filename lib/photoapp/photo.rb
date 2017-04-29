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
      @watermarked ||= begin
        date = date_text
        image.composite(logo, SouthWestGravity, 50, 40, OverCompositeOp)
          .composite(date[0], SouthWestGravity, 5, -10, OverCompositeOp)
          .composite(date[1], SouthWestGravity, 5, -10, OverCompositeOp)
      end
    end

    def with_url
      @printable ||= begin
        url = url_text
        watermark.dup
          .composite(url[0], SouthEastGravity, 40, 30, OverCompositeOp)
          .composite(url[1], SouthEastGravity, 40, 30, OverCompositeOp)
      end
    end

    def url_text
      add_shadowed_text "#{config['url_base']}/#{short}.jpg", config['font_size'], NorthEastGravity
    end

    def date_text
      date = Time.now.strftime('%b %d, %Y')
      add_shadowed_text date, config['date_font_size'], NorthEastGravity, 250
    end

    def add_shadowed_text(text, size, gravity, width=800)
      setting = config
      shadowed_text = []

      %w(#000 #fff).each do |color|
        image = Image.new(width, 70) { self.background_color = "rgba(255, 255, 255, 0" }
        txt = Draw.new
        txt.annotate(image, 0, 0, 0, 0, text) do
          txt.gravity = gravity
          txt.pointsize = size
          txt.fill = color
          txt.font = setting['font']

          if color == '#000'
            txt.stroke = color
          end
        end

        # Blur drop shadow
        if color == '#000'
          image = image.blur_image(radius=6.0, sigma=2.0)
        end

        shadowed_text.push image
      end

      shadowed_text
    end

    def write(path=nil)
      if path
        FileUtils.mkdir_p(File.dirname(path))
        with_url.write path
        cleanup
      else
        puts "writing #{upload_dest}"
        puts "writing #{print_dest}"
        FileUtils.mkdir_p(File.dirname(upload_dest))
        FileUtils.mkdir_p(File.dirname(print_dest))
        watermark.write upload_dest
        with_url.write print_dest
        cleanup
      end
    end

    def cleanup
      watermark.destroy!
      with_url.destroy!
    end

    def upload_dest
      File.join(config['upload'], short + '.jpg')
    end

    def print_dest
      File.join(config['print'], short + '.jpg')
    end

    def short
      @short ||= begin
        now = Time.now
        date = "#{now.strftime('%y')}#{now.strftime('%d')}#{now.month}"
        source = [*?a..?z] - ['o', 'l'] + [*2..9]
        short = ''
        5.times { short << source.sample.to_s }
        short = "#{short}#{date}"
        session.photos << short + '.jpg'
        short
      end
    end

  end
end
