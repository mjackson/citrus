require File.dirname(__FILE__) + '/helper'

class AndPredicateTest < Test::Unit::TestCase

  def test_terminal?
    rule = AndPredicate.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = AndPredicate.new('a')

    match = rule.match(input('b'))
    assert_equal(nil, match)

    match = rule.match(input('a'))
    assert(match)
    assert_equal('', match.value)
    assert_equal(0, match.length)
  end

  def test_to_s
    rule = AndPredicate.new('a')
    assert_equal('&"a"', rule.to_s)
  end

end
