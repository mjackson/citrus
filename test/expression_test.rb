require File.dirname(__FILE__) + '/helper'

class ExpressionTest < Test::Unit::TestCase

  include Citrus

  def test_terminal?
    rule = Expression.new(/./)
    assert(rule.terminal?)
  end

  def test_match
    rule = Expression.new(/\d+/)
    match = rule.match('123 456', 0)
    assert_equal('123', match.value)
    assert_equal(3, match.length)
    match = rule.match('123 456', 1)
    assert_equal('23', match.value)
    assert_equal(2, match.length)
    match = rule.match('123 456', 3)
    assert_equal(1, match.offset)
    assert_equal('456', match.value)
    assert_equal(3, match.length)

    rule = Expression.new(/^\d+/)
    match = rule.match(' 456', 0)
    assert_equal(nil, match)
  end

  def test_to_s
    rule = Expression.new(/\d+/)
    assert_equal('/\\d+/', rule.to_s)
  end

end
