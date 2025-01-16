module Orb
  module Parser
    def initialize(@pos : Int32, @input : String)
    end

    def next_char : Char
      @input[@pos]
    end

    def consume_char : Char
      char = next_char
      @pos += 1
      char
    end

    def consume_while(&block) : String
      String.build do |str|
        while !eof && yield next_char
          str << consume_char
        end
      end
    end

    def consume_whitespace
      consume_while &.whitespace?
    end

    def parse_name : String
      consume_while &.alphanumeric?
    end

    def starts_with(str : String) : Bool
      @input[@pos..].starts_with?(str)
    end

    def expect(str : String)
      if starts_with str
        @pos += str.size
      else
        raise Exception.new "Expected #{str} at byte #{@pos} but it was not found"
      end
    end

    def eof : Bool
      @pos >= @input.size
    end
  end
end
