require File.dirname(__FILE__) + '/helper'

class ChoiceTest < Test::Unit::TestCase

  include Citrus

  def test_terminal?
    rule = Choice.new([])
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Choice.new(%w<a b>)

    assert_equal(nil, rule.match)

    rule.match!('')
    assert(rule.match)

    # All matches after the first shouldn't match.
    assert_equal(nil, rule.match!)
  end

  def test_to_s
    rule = Choice.new(%w<a b>)
    assert_equal('"a" / "b"', rule.to_s)

    rule1 = Choice.new(%w<a b>)
    rule2 = Choice.new(%w<c d>)
    rule = Choice.new([rule1, rule2])
    assert_equal('("a" / "b") / ("c" / "d")', rule.to_s)
  end

end
