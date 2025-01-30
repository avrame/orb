require "./dom.cr"
require "./css.cr"

module Orb
  alias PropertyMap = Hash(String, Value)
  alias MatchedRule = Tuple(Specificity, Rule)
  enum Display
    Inline
    Block
    None
  end

  # Apply a stylesheet to an entire DOM tree, returning a StyledNode tree.
  def self.style_tree(root : Node, stylesheet : Stylesheet) : StyledNode
    specified_values = case root
                      in Elem
                        specified_values(root, stylesheet)
                      in Text
                        PropertyMap.new
                      in Node
                        raise Exception.new("Unknown node type")
                      end

    children = root.children.map do |child|
      style_tree(child, stylesheet)
    end

    StyledNode.new(root, specified_values, children)
  end

  # Apply styles to a single element, returning the specified values.
  def self.specified_values(elem : Elem, stylesheet : Stylesheet) : PropertyMap
    values = PropertyMap.new
    rules = matching_rules(elem, stylesheet)

    # Go through the rules from lowest to highest specificity.
    rules.sort_by! { |matched_rule| matched_rule[0] }

    rules.each do |matched_rule|
      matched_rule[1].declarations.each do |declaration|
        values[declaration.name] = declaration.value
      end
    end

    values
  end

  # Find all CSS rules that match the given element.
  def self.matching_rules(elem : Elem, stylesheet : Stylesheet) : Array(MatchedRule)
    stylesheet.rules.each_with_object([] of MatchedRule) do |rule, matched_rules|
      matched_rule = match_rule(elem, rule)
      matched_rules << matched_rule if matched_rule
    end
  end

  # If `rule` matches `elem`, return a `MatchedRule`. Otherwise return `nil`.
  def self.match_rule(elem : Elem, rule : Rule) : MatchedRule?
    selector = rule.selectors.find { |selector| matches(elem, selector) }
    if selector
      MatchedRule.new(selector.specificity, rule)
    end
  end

  def self.matches(elem : Elem, selector : Selector) : Bool
    if selector.is_a?(SimpleSelector)
      return matches_simple_selector(elem, selector)
    end
    false
  end

  def self.matches_simple_selector(elem : Elem, selector : SimpleSelector) : Bool
    # Check type selector
    if selector.tag_name && selector.tag_name != elem.tag_name
      return false
    end

    if selector.id && selector.id != elem.id
      return false
    end

    if selector.klass.any? { |k| !elem.classes.includes? k }
      return false
    end

    true
  end

  class StyledNode
    property node : Node
    property specified_values : PropertyMap
    property children : Array(StyledNode)

    def initialize(@node, @specified_values, @children)
    end

    def value(name : String) : Value?
      specified_values[name]?
    end

    def lookup(name : String, fallback_name : String, default : Value) : Value
      value(name) || value(fallback_name) || default
    end

    def display : Display
      case value("display").to_s
      when "block"
        Display::Block
      when "none"
        Display::None
      else
        Display::Inline
      end
    end
  end
end
