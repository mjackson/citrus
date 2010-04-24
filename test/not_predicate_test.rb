require File.dirname(__FILE__) + '/helper'

class NotPredicateTest < Test::Unit::TestCase

  include Citrus

  def test_terminal?
    rule = NotPredicate.new('')
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = NotPredicate.new('a')

    input = Input.new('a')
    match = rule.match(input)
    assert_equal(nil, match)

    input = Input.new('b')
    match = rule.match(input)
    assert(match)
    assert_equal('', match.value)
    assert_equal(0, match.length)

    assert_equal(false, input.done?)
  end

  def test_to_s
    rule = NotPredicate.new('a')
    assert_equal('!"a"', rule.to_s)
  end

end
