require File.expand_path('../helper', __FILE__)

class RuleTest < Test::Unit::TestCase

  module MatchModule
    def a_test
      :test
    end
  end

  NumericProc = Proc.new {
    def to_i
      text.to_i
    end

    def to_f
      text.to_f
    end
  }

  NumericModule = Module.new(&NumericProc)

  def test_new
    rule = Rule.new('"a"')
    assert(rule)
    match = rule.match(input('a'))
    assert(match)
  end

  def test_match_module
    rule = EqualRule.new('a')
    rule.extension = MatchModule
    match = rule.match(input('a'))
    assert(match)
    assert_equal(:test, match.a_test)
  end

  def test_numeric_proc
    rule = EqualRule.new(1)
    rule.extension = NumericProc
    match = rule.match(input('1'))
    assert(match)
    assert_equal(1, match.to_i)
    assert_instance_of(Float, match.to_f)
  end

  def test_numeric_module
    rule = EqualRule.new(1)
    rule.extension = NumericModule
    match = rule.match(input('1'))
    assert(match)
    assert_equal(1, match.to_i)
    assert_instance_of(Float, match.to_f)
  end

end
