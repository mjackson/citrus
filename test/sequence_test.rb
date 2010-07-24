require File.expand_path('../helper', __FILE__)

class SequenceTest < Test::Unit::TestCase

  def test_terminal?
    rule = Sequence.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Sequence.new(%w<a b>)

    match = rule.match(input(''))
    assert_equal(nil, match)

    match = rule.match(input('a'))
    assert_equal(nil, match)

    match = rule.match(input('ab'))
    assert(match)
    assert_equal('ab', match.text)
    assert_equal(2, match.length)
  end

  def test_match_mixed
    rule = Sequence.new([/\d+/, '+', /\d+/])
    match = rule.match(input('1+2'))
    assert(match)
    assert_equal('1+2', match.text)
    assert_equal(3, match.length)
  end

  def test_match_embed
    rule = Sequence.new([/[0-9]+/, Choice.new(%w<+ ->), /\d+/])
    match = rule.match(input('1+2'))
    assert(match)
    assert_equal('1+2', match.text)
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
