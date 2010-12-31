require File.expand_path('../helper', __FILE__)

class MatchTest < Test::Unit::TestCase
  def test_string_equality
    match = Match.new('hello')
    assert_equal('hello', match)
  end

  def test_match_equality
    match1 = Match.new('a')
    match2 = Match.new('a')
    assert(match1 == match2)
    assert(match2 == match1)
  end

  def test_match_inequality
    match1 = Match.new('a')
    match2 = Match.new('b')
    assert_equal(false, match1 == match2)
    assert_equal(false, match2 == match1)
  end

  def test_matches
    a = Rule.for('a')
    b = Rule.for('b')
    c = Rule.for('c')
    s = Rule.for([ a, b, c ])
    s.name = 's'
    r = Repeat.new(s, 0, Infinity)

    events = [
      r,
        s,
          a, CLOSE, 1,
          b, CLOSE, 1,
          c, CLOSE, 1,
        CLOSE, 3,
        s,
          a, CLOSE, 1,
          b, CLOSE, 1,
          c, CLOSE, 1,
        CLOSE, 3,
        s,
          a, CLOSE, 1,
          b, CLOSE, 1,
          c, CLOSE, 1,
        CLOSE, 3,
      CLOSE, 9
    ]

    match = Match.new("abcabcabc", events)
    assert(match.matches)
    assert_equal(3, match.matches.length)

    sub_events = [
      s,
        a, CLOSE, 1,
        b, CLOSE, 1,
        c, CLOSE, 1,
      CLOSE, 3
    ]

    match.matches.each do |m|
      assert_equal(sub_events, m.events)
      assert_equal("abc", m)
      assert(m.matches)
      assert_equal(3, m.matches.length)
    end
  end

  grammar :Addition do
    rule :additive do
      all(:number, :plus, label(any(:additive, :number), 'term')) {
        number.value + term.value
      }
    end

    rule :number do
      all(/[0-9]+/, :space) {
        strip.to_i
      }
    end

    rule :plus do
      all('+', :space)
    end

    rule :space do
      /[ \t]*/
    end
  end

  def test_matches2
    match = Addition.parse('+', :root => :plus)
    assert(match)
    assert(match.matches)
    assert_equal(2, match.matches.length)

    match = Addition.parse('+ ', :root => :plus)
    assert(match)
    assert(match.matches)
    assert_equal(2, match.matches.length)

    match = Addition.parse('99', :root => :number)
    assert(match)
    assert(match.matches)
    assert_equal(2, match.matches.length)

    match = Addition.parse('99 ', :root => :number)
    assert(match)
    assert(match.matches)
    assert_equal(2, match.matches.length)

    match = Addition.parse('1+2')
    assert(match)
    assert(match.matches)
    assert_equal(3, match.matches.length)
  end
end
