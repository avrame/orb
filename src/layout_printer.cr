require "./layout.cr"

module Orb
  module LayoutPrinter
    extend self

    def print_layout_tree(layout_tree : LayoutBox)
      print_layout_node(layout_tree)
    end

    def print_layout_node(layout_box : LayoutBox)
      box_type = layout_box.box_type
      puts "box_type: #{box_type.class}"
      if box_type.is_a?(BlockNode)
        node = box_type.styled_node.node
        if node.is_a?(Elem)
          puts "LayoutBox: #{node.tag_name}"
          puts "  dimensions: #{layout_box.dimensions.to_s}"
        end
      end
      puts "{"
      layout_box.children.each do |child|
        print_layout_node(child)
      end
      puts "}"
    end
  end
end
