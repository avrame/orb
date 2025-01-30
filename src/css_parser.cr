require "./parser.cr"
require "./css.cr"

module Orb
  module CssParserModule
    def self.parse(source : String) : Stylesheet
      parser = CssParser.new(0, source)
      Stylesheet.new(parser.parse_rules)
    end

    class CssParser
      include Parser

      def parse_rules : Array(Rule)
        rules = [] of Rule
        loop do
          consume_whitespace
          break if eof
          rules << parse_rule
        end
        rules
      end

      def parse_rule : Rule
        Rule.new(parse_selectors, parse_declarations)
      end

      def parse_simple_selector : SimpleSelector
        selector = SimpleSelector.new(nil, nil, [] of String)

        while !eof
          char = next_char
          case char
          when '#'
            consume_char
            selector.id = parse_identifier
          when '.'
            consume_char
            selector.klass << parse_identifier
          when '*'
            consume_char
          else
            if valid_identifier_char(char)
              selector.tag_name = parse_identifier
            else
              break
            end
          end
        end

        selector
      end

      def valid_identifier_char(c : Char) : Bool
        c.alphanumeric? || c == '-' || c == '_'
      end

      def parse_selectors : Array(Selector)
        selectors = [] of Selector
        loop do
          selectors << parse_simple_selector
          consume_whitespace
          c = next_char
          case c
          when ','
            consume_char
            consume_whitespace
          when '{'
            break
          else
            raise Exception.new "Unexpected character #{c} in selector list"
          end
        end
        selectors.sort { |a, b| a.specificity <=> b.specificity }
      end

      def parse_declarations : Array(Declaration)
        expect_char('{')
        declarations = [] of Declaration
        loop do
          consume_whitespace
          if next_char == '}'
            consume_char
            break
          end
          declarations << parse_declaration
        end
        declarations
      end

      def parse_declaration : Declaration
        name = parse_identifier
        consume_whitespace
        expect_char ':'
        consume_whitespace
        value = parse_value
        consume_whitespace
        expect_char ';'
        Declaration.new(name, value)
      end

      def parse_value : Value
        case next_char
        when '0'..'9'
          parse_length
        when '#'
          parse_color
        else
          Keyword.new(parse_identifier)
        end
      end

      def parse_length : Value
        Length.new(parse_float, parse_unit)
      end

      def parse_float : Float64
        s = consume_while { |c| c.number? || c == '.' }
        s.to_f
      end

      def parse_unit : Unit
        case parse_identifier.downcase
        when "px"
          Unit::Px
        when "em"
          Unit::Em
        when "rem"
          Unit::Rem
        else
          raise Exception.new "unrecognized unit"
        end
      end

      def parse_color : Value
        expect_char '#'
        hex = @input[@pos..@pos + 5]
        hex_bytes = hex.hexbytes
        r = hex_bytes[0]
        g = hex_bytes[1]
        b = hex_bytes[2]
        if r && g && b
          @pos += 6
          ColorValue.new(Color.new(r.to_u8, g.to_u8, b.to_u8))
        else
          raise Exception.new "Invalid color value"
        end
      end

      def parse_identifier : String
        consume_while { |c| c.alphanumeric? || c == '-' || c == '_' }
      end
    end
  end
end
