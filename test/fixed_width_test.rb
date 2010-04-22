require File.dirname(__FILE__) + '/helper'

class FixedWidthTest < Test::Unit::TestCase

  include Citrus

  def test_terminal?
    rule = FixedWidth.new('')
    assert(rule.terminal?)
  end

  def test_match
    rule = FixedWidth.new('hello')
    match = rule.match('hello world', 0)
    assert_equal('hello', match.value)
    assert_equal(5, match.length)
    match = rule.match('hello world', 1)
    assert_equal(nil, match)
  end

  def test_to_s
    rule = FixedWidth.new('a')
    assert_equal('"a"', rule.to_s)
  end

end
