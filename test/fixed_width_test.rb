require File.dirname(__FILE__) + '/helper'

class FixedWidthTest < Test::Unit::TestCase

  def test_terminal?
    rule = FixedWidth.new
    assert(rule.terminal?)
  end

  def test_match
    rule = FixedWidth.new('abc')
    match = rule.match(parser('abc'))
    assert(match)
    assert_equal('abc', match.value)
    assert_equal(3, match.length)
  end

  def test_match_short
    rule = FixedWidth.new('abc')
    match = rule.match(parser('ab'))
    assert_equal(nil, match)
  end

  def test_match_long
    rule = FixedWidth.new('abc')
    match = rule.match(parser('abcd'))
    assert(match)
    assert_equal('abc', match.value)
    assert_equal(3, match.length)
  end

  def test_to_s
    rule = FixedWidth.new('abc')
    assert_equal('"abc"', rule.to_s)
  end

end
