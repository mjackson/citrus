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

  NumericProc = Proc.new {
    def to_i
      text.to_i
    end

    def to_f
      text.to_f
    end
  }

  NumericExt = Module.new(&NumericProc)

  class NumericMatch < Match
    include NumericExt
  end

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

  def test_numeric_proc
    rule = EqualRule.new(1)
    rule.match_ext = NumericProc
    match = rule.match(input('1'))
    assert(match)
    assert_equal(1, match.to_i)
    assert_instance_of(Float, match.to_f)
  end

  def test_numeric_ext
    rule = EqualRule.new(1)
    rule.match_ext = NumericExt
    match = rule.match(input('1'))
    assert(match)
    assert_kind_of(NumericExt, match)
    assert_equal(1, match.to_i)
    assert_instance_of(Float, match.to_f)
  end

  def test_numeric_match
    rule = EqualRule.new(1)
    rule.match_class = NumericMatch
    match = rule.match(input('1'))
    assert(match)
    assert_instance_of(NumericMatch, match)
    assert_equal(1, match.to_i)
    assert_instance_of(Float, match.to_f)
  end

end
