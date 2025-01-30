require "blend2d"
require "sdl"
require "./layout.cr"

module Orb
  alias DisplayList = Array(DisplayCommand)

  alias DisplayCommand = PaintRect | RenderText # insert other commands here

  class PaintRect
    property bg_color : Color?
    property border_color : Color?
    property rect : Rect

    def initialize(@bg_color, @border_color, @rect)
    end
  end

  class PaintRoundedRect < PaintRect
    property radius : Float32

    def initialize(@bg_color, @border_color, @rect, @radius)
    end
  end

  class RenderText
    property text : String
    property rect : Rect

    def initialize(@text : String, @rect : Rect)
    end
  end

  def self.paint_surface(window, img, ticks, layout_root) : SDL::Surface
    display_list = build_display_list(layout_root)
    ctx = Blend2D::Context.new img
    ctx.fill_all
    display_list.each { |item| paint_item(window,ctx,item) }
    ctx.end
    SDL::Surface.from(img.data.pixel_data, window.width, window.height, PIXEL_FORMAT)
  end

  def self.build_display_list(layout_root : LayoutBox) : DisplayList
    list = [] of DisplayCommand
    render_layout_box(list, layout_root)
    list
  end

  def self.render_layout_box(list : DisplayList, layout_box : LayoutBox)
    bg_color = get_color(layout_box, "background-color")
    border_color = get_color(layout_box, "border-color")
    if bg_color
      list << PaintRect.new(bg_color, border_color, layout_box.dimensions.border_box)
    end
    layout_box.children.each do |child|
      render_layout_box(list, child)
    end
  end

  def self.paint_item(window : SDL::Window, ctx : Blend2D::Context, item : DisplayCommand)
    case item
    in PaintRect
      paint_rect(window, ctx, item)
    in PaintRoundedRect
      paint_rounded_rect(window, ctx, item)
    in RenderText
      render_text(ctx, item)
    end
  end

  def self.paint_rect(window : SDL::Window, ctx : Blend2D::Context, item : PaintRect)
    bg_color = item.bg_color
    border_color = item.border_color
    if bg_color
      ctx.fill_style = Blend2D::Styling::RGBA32.new(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
    else
      ctx.fill_style = Blend2D::Styling::RGBA32.new(0, 0, 0, 0)
    end
    if border_color
      ctx.stroke_style = Blend2D::Styling::RGBA32.new(border_color.r, border_color.g, border_color.b, border_color.a)
    else
      ctx.stroke_style = Blend2D::Styling::RGBA32.new(0, 0, 0, 0)
    end
    x = item.rect.x.clamp(0, window.width).to_f64
    y = item.rect.y.clamp(0, window.height).to_f64
    width = item.rect.width.clamp(0, window.width - x).to_f64
    height = item.rect.height.clamp(0, window.height - y).to_f64
    ctx.fill_rect x, y, width, height
  end

  def self.paint_rounded_rect(window : SDL::Window, ctx : Blend2D::Context, item : PaintRoundedRect)
    # TODO
  end

  def self.render_text(ctx : Blend2D::Context, item : RenderText)
    # TODO
  end

  def self.get_color(layout_box : LayoutBox, name : String) : Color?
    box_type = layout_box.box_type
    case box_type
    in BlockNode, InlineNode
      color_style = box_type.styled_node.value(name)
      if color_style.is_a?(ColorValue)
        color_style.color
      else
        nil
      end
    in AnonymousBlock
      nil
    end
  end
end

