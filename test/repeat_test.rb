require File.dirname(__FILE__) + '/helper'

class RepeatTest < Test::Unit::TestCase

  include Citrus

  Infinity = 1.0 / 0

  def test_terminal?
    rule = Repeat.new('')
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Repeat.new('hi', 1, 1)

    assert_equal(nil, rule.match)

    rule.match!('')
    assert(rule.match)
    rule.reset!

    rule.match!('')
    rule.match!('')
    assert_equal(nil, rule.match)
  end

  def test_to_s
    rule = Repeat.new('hi', 0, Infinity)
    assert_equal('"hi"*', rule.to_s)

    rule = Repeat.new('hi', 0, 1)
    assert_equal('"hi"?', rule.to_s)

    rule = Repeat.new('hi', 1, Infinity)
    assert_equal('"hi"+', rule.to_s)

    rule = Repeat.new('hi', 1, 2)
    assert_equal('"hi"1*2', rule.to_s)

    rule = Repeat.new(Choice.new(%w<a b>), 0, 1)
    assert_equal('("a" / "b")?', rule.to_s)
  end

end
