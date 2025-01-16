module Orb
  alias AttrMap = Hash(String, String)

  abstract class Node
  end

  class Text < Node
    property text : String
    property children : Array(Node)

    def initialize(@text : String)
      @children = [] of Node
    end
  end

  class Elem < Node
    property tag_name : String
    property children : Array(Node)

    def initialize(@tag_name : String, @attrs : AttrMap, @children : Array(Node))
    end
  end
end
