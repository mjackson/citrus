require File.dirname(__FILE__) + '/helper'

class ChoiceTest < Test::Unit::TestCase

  include Citrus

  def test_terminal?
    rule = Choice.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Choice.new(%w<a b>)

    match = rule.match('')
    assert_equal(nil, match)

    match = rule.match('c')
    assert_equal(nil, match)

    match = rule.match('a')
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)
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
