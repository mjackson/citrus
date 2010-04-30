require File.dirname(__FILE__) + '/helper'

class ProxyTest < Test::Unit::TestCase

  def proxy(rule)
    p = Proxy.new(rule)
    p.grammar = TestGrammar
    p
  end

  def test_terminal?
    rule = proxy(:num)
    assert(rule.terminal?)
  end

  def test_non_terminal
    rule = proxy(:alphanum)
    assert_equal(false, rule.terminal?)
  end

  def test_id
    expect = TestGrammar.rule(:num).id
    rule = proxy(:num)
    assert_equal(expect, rule.id)
  end

end
