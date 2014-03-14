require File.expand_path('../helper', __FILE__)

class ExtensionTest < Test::Unit::TestCase
  module MatchModule
    def a_test
      :test
    end
  end

  module NumericModule
    def add_one
      to_str.to_i + 1
    end
  end

  NumericProcBare = Proc.new {
    to_str.to_i + 1
  }

  def test_match_module
    rule = StringTerminal.new('abc')
    rule.extension = MatchModule
    match = rule.parse('abc')
    assert(match)
    assert_equal(:test, match.a_test)
  end

  def test_numeric_module
    rule = StringTerminal.new('1')
    rule.extension = NumericModule
    match = rule.parse('1')
    assert(match)
    assert_equal(2, match.add_one)
  end

  def test_numeric_proc_bare
    rule = StringTerminal.new('1')
    rule.extension = NumericProcBare
    match = rule.parse('1')
    assert(match)
    assert_equal(2, match.value)
  end
end
