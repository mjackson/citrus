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

    input = Input.new('')
    match = rule.match(input)
    assert(match)
    assert_equal('', match.value)
    assert_equal(0, match.length)

    input = Input.new('a')
    match = rule.match(input)
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)
  end

  def test_match_one_or_more
    rule = Repeat.new('a', 1, Infinity)

    input = Input.new('')
    match = rule.match(input)
    assert_equal(nil, match)

    input = Input.new('a')
    match = rule.match(input)
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)

    input = Input.new('a' * 200)
    match = rule.match(input)
    assert(match)
    assert_equal('a' * 200, match.value)
    assert_equal(200, match.length)
  end

  def test_match_one
    rule = Repeat.new('a', 1, 1)

    input = Input.new('')
    match = rule.match(input)
    assert_equal(nil, match)

    input = Input.new('a')
    match = rule.match(input)
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)
  end

  def test_operator
    rule = Repeat.new('', 0, Infinity)
    assert_equal('*', rule.operator)

    rule = Repeat.new('', 0, 1)
    assert_equal('?', rule.operator)

    rule = Repeat.new('', 1, Infinity)
    assert_equal('+', rule.operator)

    rule = Repeat.new('', 1, 2)
    assert_equal('1*2', rule.operator)
  end

  def test_to_s
    rule = Repeat.new('a', 0, Infinity)
    assert_equal('"a"*', rule.to_s)

    rule = Repeat.new('a', 0, 1)
    assert_equal('"a"?', rule.to_s)

    rule = Repeat.new('a', 1, Infinity)
    assert_equal('"a"+', rule.to_s)

    rule = Repeat.new(/a/, 1, 2)
    assert_equal('/a/1*2', rule.to_s)
  end

end
