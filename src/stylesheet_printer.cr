require "./style.cr"

module Orb
  module StylesheetPrinter
    extend self

    def print_stylesheet(stylesheet : Stylesheet)
      stylesheet.rules.each do |rule|
        rule.selectors.each do |selector|
          puts selector.to_s
        end
        puts "{"
        rule.declarations.each do |declaration|
          puts "  #{declaration.to_s}"
        end
        puts "}"
      end
    end
  end
end
