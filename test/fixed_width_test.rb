require File.expand_path('../helper', __FILE__)

class FixedWidthTest < Test::Unit::TestCase

  def test_terminal?
    rule = FixedWidth.new
    assert(rule.terminal?)
  end

  def test_match
    rule = FixedWidth.new('abc')
    match = rule.match(input('abc'))
    assert(match)
    assert_equal('abc', match.text)
    assert_equal(3, match.length)
  end

  def test_match_short
    rule = FixedWidth.new('abc')
    match = rule.match(input('ab'))
    assert_equal(nil, match)
  end

  def test_match_long
    rule = FixedWidth.new('abc')
    match = rule.match(input('abcd'))
    assert(match)
    assert_equal('abc', match.text)
    assert_equal(3, match.length)
  end

  def test_to_s
    rule = FixedWidth.new('abc')
    assert_equal('"abc"', rule.to_s)
  end

end
