require File.dirname(__FILE__) + '/helper'

class ChoiceTest < Test::Unit::TestCase

  def test_terminal?
    rule = Choice.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Choice.new(%w<a b>)

    match = rule.match(parser(''))
    assert_equal(nil, match)

    match = rule.match(parser('a'))
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)
  end

  def test_match_multi
    rule = Choice.new(%w<a b>)

    match = rule.match(parser('ab'))
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)

    match = rule.match(parser('ba'))
    assert(match)
    assert_equal('b', match.value)
    assert_equal(1, match.length)
  end

  def test_match_embed
    rule = Choice.new([ /\d+/, Choice.new(%w<+ ->) ])

    match = rule.match(parser('1+'))
    assert(match)
    assert_equal('1', match.value)
    assert_equal(1, match.length)

    match = rule.match(parser('+1'))
    assert(match)
    assert_equal('+', match.value)
    assert_equal(1, match.length)
  end

  def test_to_s
    rule = Choice.new(%w<a b>)
    assert_equal('"a" / "b"', rule.to_s)
  end

  def test_to_s_embed
    rule1 = Choice.new(%w<a b>)
    rule2 = Choice.new(%w<c d>)
    rule = Choice.new([rule1, rule2])
    assert_equal('("a" / "b") / ("c" / "d")', rule.to_s)
  end

end
