require 'citrus'

# A grammar for mathematical formulas that apply the basic four operations to
# non-negative numbers (integers and floats), respecting operator precedence.
module Calc
  include Citrus::Grammar

  module FirstValue
    def value
      first.value
    end
  end

  root :add

  rule :int do
    mod(/[0-9]+/) {
      def value
        text.to_i
      end
    }
  end

  rule :float do
    all(:int, '.', :int) {
      def value
        text.to_f
      end
    }
  end

  rule :num do
    mod(any(:float, :int), FirstValue)
  end

  rule :add_op do
    any('+', '-')
  end

  rule :mul_op do
    any('*', '/')
  end

  rule :add do
    mod(any(all(:mul, :add_op, :add) {
      def value
        add_op == '+' ? (mul.value + add.value) : (mul.value - add.value)
      end
    }, :mul), FirstValue)
  end

  rule :mul do
    mod(any(all(:pri, :mul_op, :mul) {
      def value
        mul_op == '*' ? (pri.value * mul.value) : (pri.value / mul.value)
      end
    }, :pri), FirstValue)
  end

  rule :pri do
    mod(any(all('(', :add, ')') {
      def value
        add.value
      end
    }, :num), FirstValue)
  end
end
