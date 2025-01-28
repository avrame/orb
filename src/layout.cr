module Orb
  # CSS box model. All sizes are in px.

  class Dimensions
    property content : Rect
    property padding : EdgeSizes
    property border : EdgeSizes
    property margin : EdgeSizes

    def initialize(@content, @padding, @border, @margin)
    end

    def initialize
      Dimensions.new(
        Rect.new(0, 0, 0, 0),
        EdgeSizes.new(0, 0, 0, 0),
        EdgeSizes.new(0, 0, 0, 0),
        EdgeSizes.new(0, 0, 0, 0)
      )
    end
  end

  class Rect
    property x : Float32
    property y : Float32
    property width : Float32
    property height : Float32

    def initialize(@x, @y, @width, @height)
    end
  end

  class EdgeSizes
    property left : Float32
    property right : Float32
    property top : Float32
    property bottom : Float32

    def initialize(@left, @right, @top, @bottom)
    end
  end

  class LayoutBox
    property dimensions : Dimensions
    property box_type : BoxType
    property children = [] of LayoutBox

    def initialize(@box_type)
      @dimensions = Dimensiones.new
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

  def build_layout_tree(style_node : StyledNode) : LayoutBox
    box_type = case style_node.display
               in .block?
                 BlockNode.new(style_node)
               in .inline?
                 InlineNode.new(style_node)
               in .none?
                 raise Exception.new "Root node has display: nonw."
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
  end
end
