require File.expand_path('../helper', __FILE__)

class SuperTest < Test::Unit::TestCase
  def test_terminal?
    rule = Super.new
    assert_equal(false, rule.terminal?)
  end

  def test_exec
    ghi = Rule.for('ghi')
    grammar1 = Grammar.new {
      rule :a, 'abc'
    }
    grammar2 = Grammar.new {
      include grammar1
      rule :a, any(ghi, sup)
    }
    rule_2a = grammar2.rule(:a)
    rule_2a_als = rule_2a.rules[0]
    rule_2a_sup = rule_2a.rules[1]
    rule_1a = grammar1.rule(:a)

    events = rule_2a.exec(Input.new('abc'))
    assert_equal([
      rule_2a,
        rule_2a_sup, CLOSE, 3,
      CLOSE, 3
    ], events)

    events = rule_2a.exec(Input.new('ghi'))
    assert_equal([
      rule_2a,
        rule_2a_als, CLOSE, 3,
      CLOSE, 3
    ], events)
  end

  def test_exec_miss
    grammar1 = Grammar.new {
      rule :a, 'abc'
    }
    grammar2 = Grammar.new {
      include grammar1
      rule :a, any('def', sup)
    }
    rule_2a = grammar2.rule(:a)
    events = rule_2a.exec(Input.new('ghi'))
    assert_equal([], events)
  end

  def test_exec_aliased
    grammar1 = Grammar.new {
      rule :a, 'abc'
      rule :b, 'def'
    }
    grammar2 = Grammar.new {
      include grammar1
      rule :a, any(sup, :b)
      rule :b, sup
    }
    rule_1a = grammar1.rule(:a)
    rule_1b = grammar1.rule(:b)
    rule_2a = grammar2.rule(:a)
    rule_2a_sup = rule_2a.rules[0]
    rule_2a_als = rule_2a.rules[1]
    rule_2b = grammar2.rule(:b)

    events = rule_2a.exec(Input.new('abc'))
    assert_equal([
      rule_2a,
        rule_2a_sup, CLOSE, 3,
      CLOSE, 3
    ], events)

    events = rule_2a.exec(Input.new('def'))
    assert_equal([
      rule_2a,
        rule_2a_als, CLOSE, 3,
      CLOSE, 3
    ], events)
  end

  def test_to_s
    rule = Super.new
    assert_equal('super', rule.to_s)
  end

  def test_to_s_with_label
    rule = Super.new
    rule.label = 'a_label'
    assert_equal('a_label:super', rule.to_s)
  end
end
