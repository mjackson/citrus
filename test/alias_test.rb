require File.dirname(__FILE__) + '/helper'
Citrus.load(File.dirname(__FILE__) + '/_files/alias')

class AliasTest < Test::Unit::TestCase

  def test_terminal?
    rule = Alias.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    grammar = Grammar.new {
      rule(:alias) { :value }
      rule(:value) { 'a' }
    }

    match = grammar.parse('a')
    assert(match)
    assert('a', match.text)
    assert(1, match.length)
  end

  def test_peg
    match = AliasOne.parse('a')
    assert(match)
  end

  def test_to_s
    rule = Alias.new(:alpha)
    assert_equal('alpha', rule.to_s)
  end

end
