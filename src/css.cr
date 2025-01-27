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
  end

  class Declaration
    property name : String
    property value : Value

    def initialize(@name, @value)
    end
  end

  alias Value = Keyword | Length | ColorValue

  class Keyword
    property keyword : String

    def initialize(@keyword)
    end
  end

  class Length
    property length : Float32
    property unit : Unit

    def initialize(@length, @unit)
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
  end

  class Color
    property r : UInt8
    property g : UInt8
    property b : UInt8
    property a : UInt8

    def initialize(@r, @g, @b, @a = 255)
    end
  end
end
