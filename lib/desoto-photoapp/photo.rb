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
      image = Image.new(800,100) { self.background_color = "rgba(255, 255, 255, 0)" }
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
      puts "writing #{upload_dest}"
      puts "writing #{print_dest}"
      FileUtils.mkdir_p(File.dirname(upload_dest))
      FileUtils.mkdir_p(File.dirname(print_dest))
      watermark.write upload_dest
      with_url.write print_dest
      cleanup
    end

    # Handle printing
    def print
      system "lpr #{print_dest}"
    end

    def add_to_photos
      `automator -i #{config['print']} #{Photoapp.gem_dir("lib/import-photos.workflow")}`
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
