require "./css.cr"

module Orb
  # Transform a style tree into a layout tree.
  def self.layout_tree(style_node : StyledNode, containing_block : Dimensions) : LayoutBox
    # The layout algorithm expects the container height to start at 0.
    # TODO: Save the initial containing block height, for calculating percent heights.
    containing_block.content.height = 0

    root_box = build_layout_tree(style_node)
    root_box.layout(containing_block)
    root_box
  end

  # CSS box model. All sizes are in px.
  def self.build_layout_tree(style_node : StyledNode) : LayoutBox
    box_type = case style_node.display
               in .block?
                 BlockNode.new(style_node)
               in .inline?
                 InlineNode.new(style_node)
               in .none?
                 raise Exception.new "Root node has display: none."
               end

    root = LayoutBox.new(box_type)

    style_node.children.each do |child|
      case child.display
      in .block?
        root.children << build_layout_tree(child)
      in .inline?
        root.get_inline_container.children << build_layout_tree(child)
      in .none?
        # Skip nodes with `display: none;`
      end
    end

    root
  end

  class Dimensions
    property content : Rect
    property padding : EdgeSizes
    property border : EdgeSizes
    property margin : EdgeSizes

    def initialize(@content, @padding, @border, @margin)
    end

    def self.default : Dimensions
      Dimensions.new(
        Rect.new(0, 0, 0, 0),
        EdgeSizes.new(0, 0, 0, 0),
        EdgeSizes.new(0, 0, 0, 0),
        EdgeSizes.new(0, 0, 0, 0)
      )
    end

    def padding_box : Rect
      @content.expanded_by(@padding)
    end

    def border_box : Rect
      padding_box().expanded_by(@border)
    end

    def margin_box : Rect
      border_box().expanded_by(@margin)
    end

    def to_s
      "content: #{@content.to_s}, padding: #{@padding.to_s}, border: #{@border.to_s}, margin: #{@margin.to_s}"
    end
  end

  class Rect
    property x : Float64
    property y : Float64
    property width : Float64
    property height : Float64

    def initialize(@x, @y, @width, @height)
    end

    def expanded_by(edge : EdgeSizes) : Rect
      Rect.new(
        @x - edge.left,
        @y - edge.top,
        @width + edge.left + edge.right,
        @height + edge.top + edge.bottom
      )
    end

    def to_s
      "x: #{@x}, y: #{@y}, width: #{@width}, height: #{@height}"
    end
  end

  class EdgeSizes
    property left : Float64
    property right : Float64
    property top : Float64
    property bottom : Float64

    def initialize(@left, @right, @top, @bottom)
    end

    def to_s
      "left: #{@left}, right: #{@right}, top: #{@top}, bottom: #{@bottom}"
    end
  end

  class LayoutBox
    property dimensions : Dimensions
    property box_type : BoxType
    property children = [] of LayoutBox

    def initialize(@box_type)
      @dimensions = Dimensions.default
    end

    def get_style_node : StyledNode
      box_type = @box_type
      case box_type
      in BlockNode, InlineNode
        box_type.styled_node
      in AnonymousBlock
        raise Exception.new "Anonymous block box has no style node"
      end
    end

    def get_inline_container : LayoutBox
      case @box_type
      in InlineNode, AnonymousBlock
        self
      in BlockNode
        if @children.last.box_type.class != AnonymousBlock
          @children << LayoutBox.new(AnonymousBlock.new)
        end
        @children.last
      end
    end

    def layout(containing_block : Dimensions)
      case @box_type
      in BlockNode
        layout_block(containing_block)
      in InlineNode
        # TODO
      in AnonymousBlock
        # TODO
      end
    end

    def layout_block(containing_block : Dimensions)
      # Child width can depend on parent width, so we need to calculate this box's width before laying out it's children
      calculate_block_width(containing_block)

      # Determine where the box is located within its container.
      calculate_block_position(containing_block)

      # Recursively lay out the children of this box.
      layout_block_children()

      # Parent height can depend on child height, so `calculate_height` must be called *after* the children are laid out.
      calculate_block_height()
    end

    def calculate_block_width(containing_block : Dimensions)
      style = get_style_node()

      # `width` has initial value `auto`.
      auto = Keyword.new("auto")
      width = style.value("width") || auto

      # margin, border, and padding have initial value 0.
      zero = Length.new(0.0, Unit::Px)

      margin_left = style.lookup("margin-left", "margin", zero)
      margin_right = style.lookup("margin-right", "margin", zero)

      border_left = style.lookup("border-left-width", "border-width", zero)
      border_right = style.lookup("border-right-width", "border-width", zero)

      padding_left = style.lookup("padding-left", "padding", zero)
      padding_right = style.lookup("padding-right", "padding", zero)

      total = [
        margin_left, margin_right,
        border_left, border_right,
        padding_left, padding_right,
        width,
      ].map { |v| v.to_px }.sum

      # If width is not auto and the total is wider than the container, treat auto margins as 0.
      if width != auto && total > containing_block.content.width
        if margin_left == auto
          margin_left = Length.new(0.0, Unit::Px)
        end
        if margin_right == auto
          margin_right = Length.new(0.0, Unit::Px)
        end
      end

      underflow = containing_block.content.width - total

      case {width == auto, margin_left == auto, margin_right == auto}
      # If the values are overconstrained, calculate margin_right.
      in {false, false, false}
        margin_right = Length.new(margin_right.to_px + underflow, Unit::Px)

      # If exactly one size is auto, its used value follows from the equality.
      in {false, false, true}
        margin_right = Length.new(underflow, Unit::Px)
      in {false, true, false}
        margin_left = Length.new(underflow, Unit::Px)
      
      # If width is set to auto, any other auto values become 0.
      in {true, _, _}
        if margin_left == auto
          margin_left = Length.new(0.0, Unit::Px)
        end
        if margin_right == auto
          margin_right = Length.new(0.0, Unit::Px)
        end

        if underflow >= 0.0
          # Expand width to fill the underflow.
          width = Length.new(underflow, Unit::Px)
        else
          # Width can't be negative. Adjust the right margin instead.
          width = Length.new(0.0, Unit::Px)
          margin_right = Length.new(margin_right.to_px + underflow, Unit::Px)
        end
      # If margin-left and margin-right are both auto, their used values are equal.
      in {false, true, true}
        margin_left = Length.new(underflow / 2.0, Unit::Px)
        margin_right = Length.new(underflow / 2.0, Unit::Px)
      end

      d = @dimensions
      d.content.width = width.to_px

      d.padding.left = padding_left.to_px
      d.padding.right = padding_right.to_px

      d.margin.left = margin_left.to_px
      d.margin.right = margin_right.to_px
    end

    def calculate_block_position(containing_block : Dimensions)
      style = get_style_node()
      d = @dimensions

      # margin, border, and padding have initial value 0.
      zero = Length.new(0.0, Unit::Px)

      # If margin-top or margin-bottom is `auto`, the used value is zero.
      d.margin.top = style.lookup("margin-top", "margin", zero).to_px
      d.margin.bottom = style.lookup("margin-bottom", "margin", zero).to_px
      
      d.border.top = style.lookup("border-top-width", "border-width", zero).to_px
      d.border.bottom = style.lookup("border-top-width", "border-width", zero).to_px

      d.padding.top = style.lookup("padding-top", "padding", zero).to_px
      d.padding.bottom = style.lookup("padding-bottom", "padding", zero).to_px

      d.content.x = containing_block.content.x + d.margin.left + d.border.left + d.padding.left

      # Position the box below all the previous boxes in the container.
      d.content.y = containing_block.content.height + containing_block.content.y
        + d.margin.top + d.border.top + d.padding.top
    end

    def layout_block_children
      @children.each do |child|
        child.layout(@dimensions)
        # Increment the height so each child is laid out below the previous one.
        @dimensions.content.height += child.dimensions.margin_box().height
      end
    end

    def calculate_block_height
      # If the height is set to an explicit length, use that exact length.
      # Otherwise, just keep the value set by `layout_block_children`.
      height = get_style_node().value("height")
      if height && height.is_a? Length
        @dimensions.content.height = height.length
      end
    end
  end

  alias BoxType = BlockNode | InlineNode | AnonymousBlock

  class BlockNode
    property styled_node : StyledNode

    def initialize(@styled_node)
    end
  end

  class InlineNode
    property styled_node : StyledNode

    def initialize(@styled_node)
    end
  end

  class AnonymousBlock
    def initialize
    end
  end
end
