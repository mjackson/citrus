require File.dirname(__FILE__) + '/helper'

class RepeatTest < Test::Unit::TestCase

  include Citrus

  Infinity = 1.0 / 0

  def test_terminal?
    rule = Repeat.new('')
    assert_equal(false, rule.terminal?)
  end

  def test_match_zero_or_one
    rule = Repeat.new('a', 0, 1)

    match = rule.match('')
    assert(match)
    assert_equal('', match.value)
    assert_equal(0, match.length)

    match = rule.match('a')
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)
  end

  def test_match_one_or_more
    rule = Repeat.new('a', 1, Infinity)

    match = rule.match('')
    assert_equal(nil, match)

    match = rule.match('a')
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)

    match = rule.match('a' * 200)
    assert(match)
    assert_equal('a' * 200, match.value)
    assert_equal(200, match.length)
  end

  def test_match_one
    rule = Repeat.new('a', 1, 1)

    match = rule.match('')
    assert_equal(nil, match)

    match = rule.match('a')
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)
  end

  def test_to_s
    rule = Repeat.new('a', 0, Infinity)
    assert_equal('"a"*', rule.to_s)

    rule = Repeat.new('a', 0, 1)
    assert_equal('"a"?', rule.to_s)

    rule = Repeat.new('a', 1, Infinity)
    assert_equal('"a"+', rule.to_s)

    rule = Repeat.new('a', 1, 2)
    assert_equal('"a"1*2', rule.to_s)

    rule = Repeat.new(Choice.new(%w<a b>), 0, 1)
    assert_equal('("a" / "b")?', rule.to_s)
  end

end
