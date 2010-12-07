require File.expand_path('../helper', __FILE__)

class AliasTest < Test::Unit::TestCase
  def test_terminal?
    rule = Alias.new
    assert_equal(false, rule.terminal?)
  end

  def test_exec
    grammar = Grammar.new {
      rule :a, :b
      rule :b, 'abc'
    }
    rule_a = grammar.rule(:a)
    rule_b = grammar.rule(:b)
    events = rule_a.exec(Input.new('abc'))
    assert_equal([rule_a, rule_b, CLOSE, 3, CLOSE, 3], events)
  end

  def test_exec_miss
    grammar = Grammar.new {
      rule :a, :b
      rule :b, 'abc'
    }
    rule = grammar.rule(:a)
    events = rule.exec(Input.new('def'))
    assert_equal([], events)
  end

  def test_exec_included
    grammar1 = Grammar.new {
      rule :a, 'abc'
    }
    grammar2 = Grammar.new {
      include grammar1
      rule :b, :a
    }
    rule_b2 = grammar2.rule(:b)
    rule_a1 = grammar1.rule(:a)
    events = rule_b2.exec(Input.new('abc'))
    assert_equal([rule_b2, rule_a1, CLOSE, 3, CLOSE, 3], events)
  end

  def test_to_s
    rule = Alias.new(:alpha)
    assert_equal('alpha', rule.to_s)
  end
end
