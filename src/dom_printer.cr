require "./dom.cr"

module Orb
  module DomPrinter
    extend self

    def print_node(node : Node, level : Int32 = 0)
      spacing = " " * level * 4
      case node
      when Text
        puts "#{spacing}Text: #{node.text}"
      when Elem
        puts "#{spacing}Elem: #{node.tag_name}"
      end
      node.children.each { |node| print_node(node, level + 1) }
    end
  end
end
