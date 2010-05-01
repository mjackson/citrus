require File.dirname(__FILE__) + '/helper'

class NotTest < Test::Unit::TestCase

  def test_terminal?
    rule = Not.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Not.new('a')

    match = rule.match(input('a'))
    assert_equal(nil, match)

    match = rule.match(input('b'))
    assert(match)
    assert_equal('', match.text)
    assert_equal(0, match.length)
  end

  def test_to_s
    rule = Not.new('a')
    assert_equal('!"a"', rule.to_s)
  end

end
