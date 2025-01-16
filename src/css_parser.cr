require "./parser.cr"
require "./css.cr"

module Orb
  class CssParser
    include Parser

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
          selector.class << parse_identifier
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

    def parse_rule : Rule
      Rule.new(parse_selectors, parse_declarations)
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
      expect_char(':')
      consume_whitespace
      value = parse_value
      consume_whitespace
      expect_char(';')
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

    def parse_float : Float32
      consume_while { |c| c.numeric? || c == '.' }
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
      hex = @input[@pos..@pos + 6]
      hex_bytes = hex.hexbytes
      ColorValue.new(
        Color.new(
          hex_bytes[0..1],
          hex_bytes[2..3],
          hex_bytes[4..5]
        )
      )
    end

    def parse_identifier : String
      consume_while { |c| c.alphanumeric? || c == '-' || c == '_' }
    end
  end
end
