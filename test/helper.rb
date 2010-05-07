lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'test/unit'
require 'citrus'

class Test::Unit::TestCase
  include Citrus

  module TestGrammar
    include Citrus::Grammar

    rule :alpha do
      /[a-zA-Z]/
    end

    rule :num do
      mod(/[0-9]/) {
        def value
          text.to_i
        end
      }
    end

    rule :alphanum do
      any(:alpha, :num)
    end
  end

  class EqualRule < Rule
    def initialize(value)
      @value = value
    end

    def match(input, offset=0)
      create_match(@value.to_s.dup) if @value.to_s == input.string
    end
  end

  def input(str='')
    Input.new(str)
  end

  module CalcTests
    def test_int
      match = Calc.parse!('3')
      assert(match)
      assert_equal('3', match.text)
      assert_equal(1, match.length)
      assert_equal(3, match.value)
    end

    def test_float
      match = Calc.parse!('1.5')
      assert(match)
      assert_equal('1.5', match.text)
      assert_equal(3, match.length)
      assert_equal(1.5, match.value)
    end

    def test_addition
      match = Calc.parse!('1+2')
      assert(match)
      assert_equal('1+2', match.text)
      assert_equal(3, match.length)
      assert_equal(3, match.value)
    end

    def test_addition_multi
      match = Calc.parse!('1+2+3')
      assert(match)
      assert_equal('1+2+3', match.text)
      assert_equal(5, match.length)
      assert_equal(6, match.value)
    end

    def test_addition_float
      match = Calc.parse!('1.5+3')
      assert(match)
      assert_equal('1.5+3', match.text)
      assert_equal(5, match.length)
      assert_equal(4.5, match.value)
    end

    def test_subtraction
      match = Calc.parse!('3-2')
      assert(match)
      assert_equal(1, match.value)
    end

    def test_subtraction_float
      match = Calc.parse!('4.5-3')
      assert(match)
      assert_equal('4.5-3', match.text)
      assert_equal(5, match.length)
      assert_equal(1.5, match.value)
    end

    def test_multiplication
      match = Calc.parse!('2*5')
      assert(match)
      assert_equal(10, match.value)
    end

    def test_multiplication_float
      match = Calc.parse!('1.5*3')
      assert(match)
      assert_equal('1.5*3', match.text)
      assert_equal(5, match.length)
      assert_equal(4.5, match.value)
    end

    def test_division
      match = Calc.parse!('20/5')
      assert(match)
      assert_equal(4, match.value)
    end

    def test_division_float
      match = Calc.parse!('4.5/3')
      assert(match)
      assert_equal('4.5/3', match.text)
      assert_equal(5, match.length)
      assert_equal(1.5, match.value)
    end

    def test_complex
      match = Calc.parse!('7*4+3.5*(4.5/3)')
      assert(match)
      assert_equal('7*4+3.5*(4.5/3)', match.text)
      assert_equal(33.25, match.value)
    end

    def test_complex_spaced
      match = Calc.parse!('7 * 4 + 3.5 * (4.5 / 3)')
      assert(match)
      assert_equal(33.25, match.value)
    end
  end

end
