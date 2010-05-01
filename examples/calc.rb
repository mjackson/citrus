require 'citrus'

# A grammar for mathematical formulas that apply the basic four operations to
# non-negative numbers (integers and floats).
module Calc
  include Citrus::Grammar

  root :add

  rule :int do
    mod(/[0-9]+/) {
      def value
        text.to_i
      end
    }
  end

  rule :float do
    mod([ :int, '.', :int ]) {
      def value
        text.to_f
      end
    }
  end

  rule :num do
    any(:float, :int)
  end

  rule :add_op do
    any('+', '-')
  end

  rule :mul_op do
    any('*', '/')
  end

  rule :add do
    any(mod([ :mul, :add_op, :add ]) {
      def value
        add_op == '+' ? (mul.value + add.value) : (mul.value - add.value)
      end
    }, :mul)
  end

  rule :mul do
    any(mod([ :pri, :mul_op, :mul ]) {
      def value
        mul_op == '*' ? (pri.value * mul.value) : (pri.value / mul.value)
      end
    }, :pri)
  end

  rule :pri do
    any(mod([ '(', :add, ')' ]) {
      def value
        add.value
      end
    }, :num)
  end
end
