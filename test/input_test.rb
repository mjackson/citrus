require File.expand_path('../helper', __FILE__)

class InputTest < Test::Unit::TestCase
  def test_new
    # to_str
    assert_equal('abc', Input.new('abc').string)

    # read
    selftext = ::File.read(__FILE__)
    ::File.open(__FILE__, 'r') do |io|
      assert_equal(selftext, Input.new(io).string)
    end

    # to_path
    path = Struct.new(:to_path).new(__FILE__)
    assert_equal(selftext, Input.new(path).string)
  end

  def test_memoized?
    assert_equal(false, Input.new('').memoized?)
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

  def test_exec
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

  def test_exec2
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
end
