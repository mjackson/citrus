require 'citrus'

# A grammar for mathematical formulas that apply the basic four operations to
# non-negative numbers (integers and floats), respecting operator precedence and
# ignoring whitespace.
module Calc
  include Citrus::Grammar

  module FirstValue
    def value
      first.value
    end
  end

  # If "additive" were not already the first rule declared in this grammar, we
  # could use the following line to make it the root rule.
  #root :additive

  rule :additive do
    mod(any(:multitive_additive, :multitive), FirstValue)
  end

  rule :multitive_additive do
    all(:multitive, :additive_op, :additive) {
      def value
        if additive_op == '+'
          multitive.value + additive.value
        else
          multitive.value - additive.value
        end
      end
    }
  end

  rule :multitive do
    mod(any(:primary_multitive, :primary), FirstValue)
  end

  rule :primary_multitive do
    all(:primary, :multitive_op, :multitive) {
      def value
        if multitive_op == '*'
          primary.value * multitive.value
        else
          primary.value / multitive.value
        end
      end
    }
  end

  rule :primary do
    mod(any(:additive_paren, :number), FirstValue)
  end

  rule :additive_paren do
    all(:lparen, :additive, :rparen) {
      def value
        additive.value
      end
    }
  end

  rule :additive_op do
    any(:plus, :minus) {
      def ==(other)
        text.strip == other
      end
    }
  end

  rule :multitive_op do
    any(:star, :slash) {
      def ==(other)
        text.strip == other
      end
    }
  end

  rule :number do
    mod(any(:float, :integer), FirstValue)
  end

  rule :float do
    all(/[0-9]+/, '.', /[0-9]+/, :space) {
      def value
        text.strip.to_f
      end
    }
  end

  rule :integer do
    all(/[0-9]+/, :space) {
      def value
        text.strip.to_i
      end
    }
  end

  rule(:lparen) { ['(', :space] }
  rule(:rparen) { [')', :space] }
  rule(:plus)   { ['+', :space] }
  rule(:minus)  { ['-', :space] }
  rule(:star)   { ['*', :space] }
  rule(:slash)  { ['/', :space] }

  rule :space do
    /[ \t\n\r]*/
  end
end
