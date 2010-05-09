require File.dirname(__FILE__) + '/helper'

class MatchTest < Test::Unit::TestCase

  Double = Grammar.new {
    include MatchTest::TestGrammar
    root :double
    rule :double do
      one_or_more(:num)
    end
  }

  Sentence = Grammar.new {
    include MatchTest::TestGrammar
    root :sentence
    rule :word do
      one_or_more(:alpha)
    end
    rule :sentence do
      [ :word, zero_or_more([ ' ', :word ]) ]
    end
  }

  def test_string
    match = Match.new('hello')
    assert_equal('hello', match.text)
    assert_equal(5, match.length)
  end

  def test_array_string
    match1 = Match.new('a')
    match2 = Match.new('b')
    match = Match.new([match1, match2])
    assert_equal('ab', match.text)
    assert_equal(2, match.length)
  end

  def test_match_data
    match = Match.new('hello world'.match(/^(\w+) /))
    assert_equal('hello ', match.text)
    assert_equal(6, match.length)
  end

  def test_array_match_data
    match1 = Match.new('hello')
    match2 = Match.new(' world'.match(/.+/))
    match = Match.new([match1, match2])
    assert_equal('hello world', match.text)
    assert_equal(11, match.length)
  end

  def test_matches
    match = Double.parse('123')
    assert(match)
    assert_equal(3, match.matches.length)
    assert_equal(3, match.find(:num).length)
  end

  def test_match
    match = Double.parse('456')
    assert(match)
    assert_equal(3, match.matches.length)

    num = match.first(:num)
    assert(num)
    assert_equal('4', num.text)
    assert_equal(4, num.value)
  end

  def test_matches_deep
    match = Sentence.parse('one two three four')
    assert(match)
    assert_equal(15, match.find(:alpha).length)
  end

end
