require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../examples/calc'

class CalcTest < Test::Unit::TestCase

  def test_int
    match = Calc.parse('3')
    assert(match)
    assert_equal('3', match.text)
    assert_equal(1, match.length)
    assert_equal(3, match.value)
  end

  def test_float
    match = Calc.parse('1.5')
    assert(match)
    assert_equal('1.5', match.text)
    assert_equal(3, match.length)
    assert_equal(1.5, match.value)
  end

  def test_addition
    match = Calc.parse('1+2')
    assert(match)
    assert_equal('1+2', match.text)
    assert_equal(3, match.length)
    assert_equal(3, match.value)
  end

  def test_addition_multi
    match = Calc.parse('1+2+3')
    assert(match)
    assert_equal('1+2+3', match.text)
    assert_equal(5, match.length)
    assert_equal(6, match.value)
  end

  def test_addition_float
    match = Calc.parse('1.5+3')
    assert(match)
    assert_equal('1.5+3', match.text)
    assert_equal(5, match.length)
    assert_equal(4.5, match.value)
  end

  def test_subtraction
    match = Calc.parse('3-2')
    assert(match)
    assert_equal(1, match.value)
  end

  def test_subtraction_float
    match = Calc.parse('4.5-3')
    assert(match)
    assert_equal('4.5-3', match.text)
    assert_equal(5, match.length)
    assert_equal(1.5, match.value)
  end

  def test_multiplication
    match = Calc.parse('2*5')
    assert(match)
    assert_equal(10, match.value)
  end

  def test_multiplication_float
    match = Calc.parse('1.5*3')
    assert(match)
    assert_equal('1.5*3', match.text)
    assert_equal(5, match.length)
    assert_equal(4.5, match.value)
  end

  def test_division
    match = Calc.parse('20/5')
    assert(match)
    assert_equal(4, match.value)
  end

  def test_division_float
    match = Calc.parse('4.5/3')
    assert(match)
    assert_equal('4.5/3', match.text)
    assert_equal(5, match.length)
    assert_equal(1.5, match.value)
  end

  def test_complex
    match = Calc.parse('7*4+3.5*(4.5/3)')
    assert(match)
    assert_equal('7*4+3.5*(4.5/3)', match.text)
    assert_equal(33.25, match.value)
  end

end
