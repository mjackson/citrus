require File.dirname(__FILE__) + '/helper'
Citrus.load(File.dirname(__FILE__) + '/_files/alias')

class AliasTest < Test::Unit::TestCase

  def test_terminal?
    rule = Alias.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    grammar = Grammar.new {
      rule :a, :b
      rule :b, 'b'
    }

    match = grammar.parse('b')
    assert(match)
    assert('b', match.text)
    assert(1, match.length)
  end

  def test_match_renamed
    grammar = Grammar.new {
      rule :a, ext(:b) {
        def value
          'a' + text
        end
      }
      rule :b, 'b'
    }

    match = grammar.parse('b')
    assert(match)
    assert('ab', match.value)

    assert_raise RuntimeError do
      match.b
    end
  end

  def test_peg
    match = AliasOne.parse('a')
    assert(match)
  end

  def test_included
    grammar1 = Grammar.new {
      rule :a, 'a'
    }

    grammar2 = Grammar.new {
      include grammar1
      rule :b, :a
    }

    match = grammar2.parse('a')
    assert(match)
  end

  def test_to_s
    rule = Alias.new(:alpha)
    assert_equal('alpha', rule.to_s)
  end

end
