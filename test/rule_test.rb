require File.dirname(__FILE__) + '/helper'

class RuleTest < Test::Unit::TestCase

  module MatchExt
    def a_test; end
  end

  class MatchClass < Match
    def a_test; end
  end

  # Invalid because it does not extend Citrus::Match.
  class InvalidMatchClass; end

  def test_match_name
    rule = EqualRule.new('a')
    rule.match_name = 'a_match'
    match = rule.match(input('a'))
    assert(match)
    assert_equal(:a_match, match.name)
  end

  def test_invalid_match_class
    rule = EqualRule.new('a')
    assert_raise(ArgumentError) {
      rule.match_class = InvalidMatchClass
    }
  end

  def test_match_class
    rule = EqualRule.new('a')
    rule.match_class = MatchClass
    match = rule.match(input('a'))
    assert(match)
    assert_instance_of(MatchClass, match)
    assert_respond_to(match, :a_test)
  end

  def test_match_ext
    rule = EqualRule.new('a')
    rule.match_ext = MatchExt
    match = rule.match(input('a'))
    assert(match)
    assert_kind_of(MatchExt, match)
    assert_respond_to(match, :a_test)
  end

end
