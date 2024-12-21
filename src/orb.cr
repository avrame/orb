require "blend2d"
require "sdl"

module Orb
  VERSION = "0.1.0"
  PIXEL_FORMAT = SDL.alloc_format(LibSDL::PixelFormatEnum::RGB888)

  SDL.init(SDL::Init::VIDEO)
  at_exit { SDL.quit }

  window = SDL::Window.new("SDL Tutorial", 640, 480)
  renderer = SDL::Renderer.new(window)

  loop do
    case event = SDL::Event.wait
    when SDL::Event::Quit
      break
    end

    renderer.clear
    renderer.copy(draw_image)
    renderer.present
  end

  def self.uint32_slice_to_uint8_slice(slice : Slice(UInt32)) : Slice(UInt8)
    result = Slice(UInt8).new(slice.size * 4)
    slice.each_with_index do |value, index|
      result[index * 4] = (value >> 24) & 0xFF
      result[index * 4 + 1] = (value >> 16) & 0xFF
      result[index * 4 + 2] = (value >> 8) & 0xFF
      result[index * 4 + 3] = value & 0xFF
    end
    result
  end

  def self.draw_image
    img = Blend2D::Image.new 800, 600
    ctx = Blend2D::Context.new img

    ctx.fill_all

    radial_gradient = Blend2D::Gradient.radial 180, 180, 180, 180, 180
    radial_gradient.add_stop 0.0, 0xFFFFFFFF
    radial_gradient.add_stop 1.0, 0xFFFF6F3F # ARGB order

    ctx.fill_circle cx: 180, cy: 180, r: 160, style: radial_gradient

    linear_gradient = Blend2D::Gradient.linear 195, 195, 470, 470
    linear_gradient.add_stop 0.0, 0xFFFFFFFF
    linear_gradient.add_stop 1.0, 0xFF3F9FFF
    round_rect = Blend2D::RoundRect.new x: 195, y: 195, w: 270, h: 270, r: 25

    ctx.comp_op = :difference
    ctx.fill_geometry round_rect, linear_gradient

    face = Blend2D::FontFace.new "#{__DIR__}/ABeeZee-Regular.ttf"
    font = Blend2D::Font.new face, 50.0

    ctx.fill_style = 0xFFFFFFFF_u32
    ctx.fill_text({60, 80}, font, "Hello Blend2D")

    # ctx.rotate speed * Math::PI / 180.0
    ctx.fill_text Blend2D::Point.new(250, 80), font, "Rotated Text"

    ctx.end
    # img.write_to_file "#{__DIR__}/composition.png"

    pixel_data = img.data.pixel_data
    pixel_data_bytes = Slice(UInt8).new(4 * pixel_data.size)
    pixel_data.each_with_index do |pixel, i|
      bytes = uninitialized UInt8[4]
      IO::ByteFormat::LittleEndian.encode(pixel, bytes.to_slice)
      pixel_data_bytes[i * 4] = bytes[0]
      pixel_data_bytes[i * 4 + 1] = bytes[1]
      pixel_data_bytes[i * 4 + 2] = bytes[2]
      pixel_data_bytes[i * 4 + 3] = bytes[3]
    end
    SDL::Surface.from(pixel_data_bytes, 800, 600, PIXEL_FORMAT)
  end
end
