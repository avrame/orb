require "blend2d"
require "sdl"
require "./html_parser.cr"
require "./css_parser.cr"
require "./dom_printer.cr"
require "./stylesheet_printer.cr"
require "./layout_printer.cr"
require "./style.cr"
require "./layout.cr"
require "./painting.cr"

module Orb
  VERSION      = "0.1.0"
  PIXEL_FORMAT = SDL.alloc_format(LibSDL::PixelFormatEnum::ARGB8888)

  SDL.init(SDL::Init::VIDEO | SDL::Init::TIMER)
  at_exit { SDL.quit }

  window = SDL::Window.new("SDL Tutorial", 1024, 800)
  viewport = Dimensions.default
  viewport.content.width = window.width
  viewport.content.height = window.height

  renderer = SDL::Renderer.new(window)
  img = Blend2D::Image.new window.width, window.height

  html_file = File.read("src/test.html")
  css_file = File.read("src/test.css")

  root_node = HtmlParserModule.parse(html_file)
  stylesheet = CssParserModule.parse(css_file)
  # StylesheetPrinter.print_stylesheet(stylesheet)
  style_root = style_tree(root_node, stylesheet)
  # DomPrinter.print_node(style_root)
  layout_root = layout_tree(style_root, viewport)
  # LayoutPrinter.print_layout_tree(layout_root)

  loop do
    ticks = SDL.get_ticks_64

    case event = SDL::Event.poll
    when SDL::Event::Quit
      break
    end

    renderer.clear
    surface = paint_surface(window, img, ticks, layout_root)
    renderer.copy(SDL::Texture.from(surface, renderer))
    renderer.present
  end
end
