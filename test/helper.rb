lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'test/unit'
require 'citrus/debug'

class Test::Unit::TestCase
  include Citrus

  def input(str='')
    Input.new(str)
  end

  module TestGrammar
    include Citrus::Grammar

    rule :alpha do
      /[a-zA-Z]/
    end

    rule :num do
      ext(/[0-9]/) {
        def value
          text.to_i
        end
      }
    end

    rule :alphanum do
      any(:alpha, :num)
    end
  end

  class EqualRule
    include Citrus::Rule

    def initialize(value)
      @value = value
    end

    def match(input, offset=0)
      create_match(@value.to_s.dup, offset) if @value.to_s == input.string
    end
  end

  module CalcTestMethods
    # A helper method that tests the successful parsing and evaluation of the
    # given mathematical expression.
    def do_test(expr)
      match = Calc.parse(expr)
      assert(match)
      assert_equal(expr, match.text)
      assert_equal(expr.length, match.length)
      assert_equal(eval(expr), match.value)
    end

    def test_int
      do_test('3')
    end

    def test_float
      do_test('1.5')
    end

    def test_addition
      do_test('1+2')
    end

    def test_addition_multi
      do_test('1+2+3')
    end

    def test_addition_float
      do_test('1.5+3')
    end

    def test_subtraction
      do_test('3-2')
    end

    def test_subtraction_float
      do_test('4.5-3')
    end

    def test_multiplication
      do_test('2*5')
    end

    def test_multiplication_float
      do_test('1.5*3')
    end

    def test_division
      do_test('20/5')
    end

    def test_division_float
      do_test('4.5/3')
    end

    def test_complex
      do_test('7*4+3.5*(4.5/3)')
    end

    def test_complex_spaced
      do_test('7 * 4 + 3.5 * (4.5 / 3)')
    end

    def test_complex_with_underscores
      do_test('(12_000 / 3) * 2.5')
    end

    def test_modulo
      do_test('3 % 2 + 4')
    end

    def test_exponent
      do_test('2**9')
    end

    def test_exponent_float
      do_test('2**2.2')
    end

    def test_negative_exponent
      do_test('2**-3')
    end

    def test_exponent_exponent
      do_test('2**2**2')
    end

    def test_exponent_group
      do_test('2**(3+1)')
    end

    def test_negative
      do_test('-5')
    end

    def test_double_negative
      do_test('--5')
    end

    def test_complement
      do_test('~4')
    end

    def test_double_complement
      do_test('~~4')
    end

    def test_mixed_unary
      do_test('~-4')
    end

    def test_complex_with_negatives
      do_test('4 * -7 / (8.0 + 1_2)**2')
    end
  end
end
