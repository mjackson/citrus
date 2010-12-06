require File.expand_path('../helper', __FILE__)

class InputTest < Test::Unit::TestCase
  def test_memoized?
    input = Input.new('')
    input.memoize!
    assert(input.memoized?)
  end

  def test_offsets_new
    input = Input.new("abc\ndef\nghi")
    assert_equal(0, input.line_offset)
    assert_equal(0, input.line_index)
    assert_equal(1, input.line_number)
    assert_equal("abc\n", input.line)
  end

  def test_offsets_advanced
    input = Input.new("abc\ndef\nghi")
    input.pos = 6
    assert_equal(2, input.line_offset)
    assert_equal(1, input.line_index)
    assert_equal(2, input.line_number)
    assert_equal("def\n", input.line)
  end

  def test_events
    a = Rule.for('a')
    b = Rule.for('b')
    c = Rule.for('c')
    s = Rule.for([ a, b, c ])
    r = Repeat.new(s, 0, Infinity)

    input = Input.new("abcabcabc")
    events = input.exec(r)

    expected_events = [
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

    assert_equal(expected_events, events)
  end

  def test_events2
    a = Rule.for('a')
    b = Rule.for('b')
    c = Choice.new([ a, b ])
    r = Repeat.new(c, 0, Infinity)
    s = Rule.for([ a, r ])

    input = Input.new('abbababba')
    events = input.exec(s)

    expected_events = [
      s.id,
        a.id, CLOSE, 1,
        r.id,
          c.id,
            b.id, CLOSE, 1,
          CLOSE, 1,
          c.id,
            b.id, CLOSE, 1,
          CLOSE, 1,
          c.id,
            a.id, CLOSE, 1,
          CLOSE, 1,
          c.id,
            b.id, CLOSE, 1,
          CLOSE, 1,
          c.id,
            a.id, CLOSE, 1,
          CLOSE, 1,
          c.id,
            b.id, CLOSE, 1,
          CLOSE, 1,
          c.id,
            b.id, CLOSE, 1,
          CLOSE, 1,
          c.id,
            a.id, CLOSE, 1,
          CLOSE, 1,
        CLOSE, 8,
      CLOSE, 9
    ]

    assert_equal(expected_events, events)
  end

  grammar :LetterA do
    rule :top do
      any(:three_as, :two_as, :one_a)
    end

    rule :three_as do
      rep(:one_a, 3, 3)
    end

    rule :two_as do
      rep(:one_a, 2, 2)
    end

    rule :one_a do
      "a"
    end
  end

  def test_cache_hits1
    input = Input.new('a')
    input.memoize!
    input.exec(LetterA.rule(:top))
    assert_equal(3, input.cache_hits)
  end

  def test_cache_hits2
    input = Input.new('aa')
    input.memoize!
    input.exec(LetterA.rule(:top))
    assert_equal(2, input.cache_hits)
  end

  def test_cache_hits3
    input = Input.new('aaa')
    input.memoize!
    input.exec(LetterA.rule(:top))
    assert_equal(0, input.cache_hits)
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

  def test_match
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
