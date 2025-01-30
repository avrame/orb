module Orb
  class Stylesheet
    property rules : Array(Rule)

    def initialize(@rules)
    end
  end

  class Rule
    property selectors : Array(Selector)
    property declarations : Array(Declaration)

    def initialize(@selectors, @declarations)
    end
  end

  alias Specificity = Tuple(Int32, Int32, Int32)

  module Selector
    def specificity : Specificity
      a = @id.nil? ? 0 : 1
      b = @klass.size
      c = @tag_name.nil? ? 0 : 1
      {a, b, c}
    end
  end

  class SimpleSelector
    include Selector
    property tag_name : String?
    property id : String?
    property klass : Array(String)

    def initialize(@tag_name, @id, @klass)
    end

    def to_s
      "tag: #{@tag_name}, id: #{@id}, klass: #{@klass.join(".")}"
    end
  end

  class Declaration
    property name : String
    property value : Value

    def initialize(@name, @value)
    end

    def to_s
      "#{@name}: #{@value.to_s}"
    end
  end

  alias Value = Keyword | Length | ColorValue

  class Keyword
    property keyword : String

    def initialize(@keyword)
    end

    def to_px
      0.0
    end

    def to_s
      @keyword
    end
  end

  class Length
    property length : Float64
    property unit : Unit

    def initialize(@length, @unit)
    end

    def to_px
      @length
    end

    def to_s
      "#{@length}#{@unit}"
    end
  end

  enum Unit
    Px
    Em
    Rem
  end

  class ColorValue
    property color : Color

    def initialize(@color)
    end

    def to_px
      0.0
    end

    def to_s
      @color.to_s
    end
  end

  class Color
    property r : UInt8
    property g : UInt8
    property b : UInt8
    property a : UInt8

    def initialize(@r, @g, @b, @a = 255)
    end

    def to_s
      "rgba(#{@r}, #{@g}, #{@b}, #{@a})"
    end
  end
end
