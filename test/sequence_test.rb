require File.dirname(__FILE__) + '/helper'

class SequenceTest < Test::Unit::TestCase

  def test_terminal?
    rule = Sequence.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Sequence.new(%w<a b>)

    match = rule.match(parser(''))
    assert_equal(nil, match)

    match = rule.match(parser('a'))
    assert_equal(nil, match)

    match = rule.match(parser('ab'))
    assert(match)
    assert_equal('ab', match.value)
    assert_equal(2, match.length)
  end

  def test_match_mixed
    rule = Sequence.new([/\d+/, '+', /\d+/])
    match = rule.match(parser('1+2'))
    assert(match)
    assert_equal('1+2', match.value)
    assert_equal(3, match.length)
  end

  def test_match_embed
    rule = Sequence.new([/[0-9]+/, Choice.new(%w<+ ->), /\d+/])
    match = rule.match(parser('1+2'))
    assert(match)
    assert_equal('1+2', match.value)
    assert_equal(3, match.length)
  end

  def test_to_s
    rule = Sequence.new(%w<a b>)
    assert_equal('"a" "b"', rule.to_s)
  end

  def test_to_s_embed
    rule1 = Sequence.new(%w<a b>)
    rule2 = Sequence.new(%w<c d>)
    rule = Sequence.new([rule1, rule2])
    assert_equal('("a" "b") ("c" "d")', rule.to_s)
  end

end
