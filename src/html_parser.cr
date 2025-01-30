require "./parser.cr"
require "./dom.cr"

module Orb
  module HtmlParserModule
    def self.parse(source : String) : Node
      parser = HtmlParser.new(0, source)
      nodes = parser.parse_nodes
      if nodes.size == 1
        return nodes[0]
      else
        return Elem.new("html", Hash(String, String).new, nodes)
      end
    end

    class HtmlParser
      include Parser

      def parse_node : Node
        if starts_with "<"
          parse_element
        else
          parse_text
        end
      end

      def parse_text : Node
        Text.new(consume_while { |c| c != '<' })
      end

      def parse_element : Node
        # Opening tag.
        expect "<"
        tag_name = parse_name
        attrs = parse_attributes
        expect ">"

        # Contents.
        children = parse_nodes

        # Closing tag.
        expect "</"
        expect tag_name
        expect ">"

        Elem.new(tag_name, attrs, children)
      end

      def parse_attr : Tuple(String, String)
        name = parse_name
        expect "="
        value = parse_attr_value
        {name, value}
      end

      def parse_attr_value : String
        open_quote = consume_char
        value = consume_while { |c| c != open_quote }
        close_quote = consume_char
        value
      end

      def parse_attributes : AttrMap
        attributes = Hash(String, String).new
        loop do
          consume_whitespace
          if next_char == '>'
            break
          end
          name_and_value = parse_attr
          name = name_and_value[0]
          value = name_and_value[1]
          attributes[name] = value
        end
        attributes
      end

      def parse_nodes : Array(Node)
        nodes = [] of Node
        loop do
          consume_whitespace
          if eof || starts_with "</"
            break
          end
          nodes << parse_node
        end
        nodes
      end
    end
  end
end
