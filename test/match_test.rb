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

  def test_names
    a = Rule.for('a')
    a.name = 'a'
    b = Rule.for('b')
    b.name = 'b'
    c = Rule.for('c')
    c.name = 'c'
    s = Rule.for([ a, b, c ])
    s.name = 's'
    r = Repeat.new(s, 0, Infinity)
    r.name = 'r'

    events = [
      r.id,
        s.id,
          a.id, CLOSE, 1,
          b.id, CLOSE, 1,
          c.id, CLOSE, 1,
        CLOSE, 3,
        s.id,
          a.id, CLOSE, 1,
          b.id, CLOSE, 1,
          c.id, CLOSE, 1,
        CLOSE, 3,
        s.id,
          a.id, CLOSE, 1,
          b.id, CLOSE, 1,
          c.id, CLOSE, 1,
        CLOSE, 3,
      CLOSE, 9
    ]

    match = Match.new("abcabcabc", events)
    assert(match.names)
    assert_equal([:r], match.names)

    match.matches.each do |m|
      assert_equal([:s], m.names)
    end
  end

  def test_matches
    a = Rule.for('a')
    b = Rule.for('b')
    c = Rule.for('c')
    s = Rule.for([ a, b, c ])
    s.name = 's'
    r = Repeat.new(s, 0, Infinity)

    events = [
      r.id,
        s.id,
          a.id, CLOSE, 1,
          b.id, CLOSE, 1,
          c.id, CLOSE, 1,
        CLOSE, 3,
        s.id,
          a.id, CLOSE, 1,
          b.id, CLOSE, 1,
          c.id, CLOSE, 1,
        CLOSE, 3,
        s.id,
          a.id, CLOSE, 1,
          b.id, CLOSE, 1,
          c.id, CLOSE, 1,
        CLOSE, 3,
      CLOSE, 9
    ]

    match = Match.new("abcabcabc", events)
    assert(match.matches)
    assert_equal(3, match.matches.length)

    sub_events = [
      s.id,
        a.id, CLOSE, 1,
        b.id, CLOSE, 1,
        c.id, CLOSE, 1,
      CLOSE, 3
    ]

    match.matches.each do |m|
      assert_equal(sub_events, m.events)
      assert_equal(:s, m.name)
      assert_equal("abc", m)
      assert(m.matches)
      assert_equal(3, m.matches.length)
    end
  end
end
