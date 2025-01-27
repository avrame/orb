require "./css.cr"

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

    def id : String
      @attrs["id"]
    end

    def classes : Set
      classes = @attrs["class"]?
      if classes
        Set.new classes.split(" ").map &.strip
      else
        Set.new
      end
    end
  end
end
