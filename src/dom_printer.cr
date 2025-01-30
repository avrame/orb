require "./style.cr"

module Orb
  module DomPrinter
    extend self

    def print_node(styled_node : StyledNode, level : Int32 = 0)
      spacing = " " * level * 4
      node = styled_node.node
      case node
      when Text
        puts "#{spacing}Text: #{node.text}"
      when Elem
        puts "#{spacing}Elem: #{node.tag_name}"
        puts "#{spacing}Styles:"
        styled_node.specified_values.each do |key, value|
          puts "#{spacing}  #{key}: #{value.to_s}"
        end
      end
      styled_node.children.each { |styled_node| print_node(styled_node, level + 1) }
    end
  end
end
