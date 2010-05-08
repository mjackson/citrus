require File.dirname(__FILE__) + '/helper'
Citrus.load(File.dirname(__FILE__) + '/_files/super')

class SuperTest < Test::Unit::TestCase

  def test_terminal?
    rule = Super.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    grammar1 = Grammar.new {
      rule(:value) { 'a' }
    }

    grammar2 = Grammar.new {
      include grammar1
      rule (:value) { any('b', sup) }
    }

    match = grammar2.parse!('b')
    assert(match)
    assert('b', match.text)
    assert(1, match.length)

    match = grammar2.parse!('a')
    assert(match)
    assert('a', match.text)
    assert(1, match.length)
  end

  def test_peg
    match = SuperTwo.parse!('2')
    assert(match)

    match = SuperTwo.parse!('1')
    assert(match)
  end

  def test_to_s
    rule = Super.new
    assert_equal('super', rule.to_s)
  end

end
