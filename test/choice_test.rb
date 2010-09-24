require File.expand_path('../helper', __FILE__)

class ChoiceTest < Test::Unit::TestCase

  def test_terminal?
    rule = Choice.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Choice.new(%w<a b>)

    match = rule.match(input(''))
    assert_equal(nil, match)

    match = rule.match(input('a'))
    assert(match)
    assert_equal('a', match)
    assert_equal(1, match.length)
  end

  def test_match_multi
    rule = Choice.new(%w<a b>)

    match = rule.match(input('ab'))
    assert(match)
    assert_equal('a', match)
    assert_equal(1, match.length)

    match = rule.match(input('ba'))
    assert(match)
    assert_equal('b', match)
    assert_equal(1, match.length)
  end

  def test_match_embed
    rule = Choice.new([ /\d+/, Choice.new(%w<+ ->) ])

    match = rule.match(input('1+'))
    assert(match)
    assert_equal('1', match)
    assert_equal(1, match.length)

    match = rule.match(input('+1'))
    assert(match)
    assert_equal('+', match)
    assert_equal(1, match.length)
  end

  def test_to_s
    rule = Choice.new(%w<a b>)
    assert_equal('"a" | "b"', rule.to_s)
  end

  def test_to_s_embed
    rule1 = Choice.new(%w<a b>)
    rule2 = Choice.new(%w<c d>)
    rule = Choice.new([rule1, rule2])
    assert_equal('("a" | "b") | ("c" | "d")', rule.to_s)
  end

end
