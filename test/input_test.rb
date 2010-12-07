require File.expand_path('../helper', __FILE__)

class InputTest < Test::Unit::TestCase
  def test_memoized?
    assert !Input.new('').memoized?
    assert MemoizingInput.new('').memoized?
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
      s,
        a, CLOSE, 1,
        r,
          c,
            b, CLOSE, 1,
          CLOSE, 1,
          c,
            b, CLOSE, 1,
          CLOSE, 1,
          c,
            a, CLOSE, 1,
          CLOSE, 1,
          c,
            b, CLOSE, 1,
          CLOSE, 1,
          c,
            a, CLOSE, 1,
          CLOSE, 1,
          c,
            b, CLOSE, 1,
          CLOSE, 1,
          c,
            b, CLOSE, 1,
          CLOSE, 1,
          c,
            a, CLOSE, 1,
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
    input = MemoizingInput.new('a')
    input.exec(LetterA.rule(:top))
    assert_equal(3, input.cache_hits)
  end

  def test_cache_hits2
    input = MemoizingInput.new('aa')
    input.exec(LetterA.rule(:top))
    assert_equal(2, input.cache_hits)
  end

  def test_cache_hits3
    input = MemoizingInput.new('aaa')
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
