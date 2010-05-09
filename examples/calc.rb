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

  rule :term do
    mod(any(:additive, :factor), FirstValue)
  end

  rule :additive do
    all(:factor, :additive_op, :term) {
      def value
        if additive_op == '+'
          factor.value + term.value
        else
          factor.value - term.value
        end
      end
    }
  end

  rule :factor do
    mod(any(:multiplicative, :primary), FirstValue)
  end

  rule :multiplicative do
    all(:primary, :multiplicative_op, :factor) {
      def value
        if multiplicative_op == '*'
          primary.value * factor.value
        else
          primary.value / factor.value
        end
      end
    }
  end

  rule :primary do
    mod(any(:term_paren, :number), FirstValue)
  end

  rule :term_paren do
    all(:lparen, :term, :rparen) {
      def value
        term.value
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

  rule :multiplicative_op do
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
