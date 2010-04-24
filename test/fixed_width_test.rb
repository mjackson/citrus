require File.dirname(__FILE__) + '/helper'

class FixedWidthTest < Test::Unit::TestCase

  include Citrus

  def test_terminal?
    rule = FixedWidth.new('')
    assert(rule.terminal?)
  end

  def test_match
    rule = FixedWidth.new('hello')

    input = Input.new('hello world')
    match = rule.match(input)
    assert(match)
    assert_equal('hello', match.value)
    assert_equal(5, match.length)

    match = rule.match(input)
    assert_equal(nil, match)

    rule = FixedWidth.new(' world')
    match = rule.match(input)
    assert(match)
    assert_equal(' world', match.value)
    assert_equal(6, match.length)

    assert(input.done?)
  end

  def test_to_s
    rule = FixedWidth.new('a')
    assert_equal('"a"', rule.to_s)
  end

end
