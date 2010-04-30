require File.dirname(__FILE__) + '/helper'

class RepeatTest < Test::Unit::TestCase

  def test_terminal?
    rule = Repeat.new
    assert_equal(false, rule.terminal?)
  end

  def test_match_zero_or_one
    rule = Repeat.new('a', 0, 1)

    match = rule.match(input(''))
    assert(match)
    assert_equal('', match.text)
    assert_equal(0, match.length)

    match = rule.match(input('a'))
    assert(match)
    assert_equal('a', match.text)
    assert_equal(1, match.length)
  end

  def test_match_one_or_more
    rule = Repeat.new('a', 1, Infinity)

    match = rule.match(input(''))
    assert_equal(nil, match)

    match = rule.match(input('a'))
    assert(match)
    assert_equal('a', match.text)
    assert_equal(1, match.length)

    match = rule.match(input('a' * 200))
    assert(match)
    assert_equal('a' * 200, match.text)
    assert_equal(200, match.length)
  end

  def test_match_one
    rule = Repeat.new('a', 1, 1)

    match = rule.match(input(''))
    assert_equal(nil, match)

    match = rule.match(input('a'))
    assert(match)
    assert_equal('a', match.text)
    assert_equal(1, match.length)
  end

  def test_operator
    rule = Repeat.new('', 1, 2)
    assert_equal('1*2', rule.operator)
  end

  def test_operator_asterisk
    rule = Repeat.new('', 0, Infinity)
    assert_equal('*', rule.operator)
  end

  def test_operator_question_mark
    rule = Repeat.new('', 0, 1)
    assert_equal('?', rule.operator)
  end

  def test_operator_plus
    rule = Repeat.new('', 1, Infinity)
    assert_equal('+', rule.operator)
  end

  def test_to_s
    rule = Repeat.new(/a/, 1, 2)
    assert_equal('/a/1*2', rule.to_s)
  end

  def test_to_s_asterisk
    rule = Repeat.new('a', 0, Infinity)
    assert_equal('"a"*', rule.to_s)
  end

  def test_to_s_question_mark
    rule = Repeat.new('a', 0, 1)
    assert_equal('"a"?', rule.to_s)
  end

  def test_to_s_plus
    rule = Repeat.new('a', 1, Infinity)
    assert_equal('"a"+', rule.to_s)
  end

end
