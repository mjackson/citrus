require File.expand_path('../helper', __FILE__)

class StringTerminalTest < Test::Unit::TestCase

  def test_terminal?
    rule = StringTerminal.new
    assert(rule.terminal?)
  end

  def test_match
    rule = StringTerminal.new('abc')
    match = rule.match(input('abc'))
    assert(match)
    assert_equal('abc', match)
    assert_equal(3, match.length)
  end

  def test_match_short
    rule = StringTerminal.new('abc')
    match = rule.match(input('ab'))
    assert_equal(nil, match)
  end

  def test_match_long
    rule = StringTerminal.new('abc')
    match = rule.match(input('abcd'))
    assert(match)
    assert_equal('abc', match)
    assert_equal(3, match.length)
  end

  def test_match_case_insensitive
    rule = StringTerminal.new('abc', Regexp::IGNORECASE)
    match = rule.match(input('abc'))
    assert(match)
    assert_equal('abc', match)

    match = rule.match(input('ABC'))
    assert(match)
    assert_equal('ABC', match)
  end

  def test_to_s
    rule = StringTerminal.new('abc')
    assert_equal('"abc"', rule.to_s)

    rule = StringTerminal.new('abc', Regexp::IGNORECASE)
    assert_equal('`abc`', rule.to_s)
  end

end
