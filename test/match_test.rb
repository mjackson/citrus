require File.expand_path('../helper', __FILE__)

class MatchTest < Test::Unit::TestCase

  def test_string
    match = Match.new('hello')
    assert_equal('hello', match)
    assert_equal(5, match.length)
  end

  def test_array_string
    match1 = Match.new('a')
    match2 = Match.new('b')
    match = Match.new([match1, match2])
    assert_equal('ab', match)
    assert_equal(2, match.length)
    assert_equal(2, match.matches.length)
  end

  def test_equality
    match1 = Match.new('a')
    match2 = Match.new('a')
    assert(match1 == 'a')
    assert(match1 == match2)
    assert(match2 == match1)

    match3 = Match.new('b')
    assert_equal(false, match1 == match3)
    assert_equal(false, match3 == match1)
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
    assert_equal('4', num)
    assert_equal(4, num.value)
  end

  def test_matches_deep
    match = Words.parse('one two three four')
    assert(match)
    assert_equal(15, match.find(:alpha).length)
  end

end
