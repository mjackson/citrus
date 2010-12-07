require File.expand_path('../helper', __FILE__)

class SequenceTest < Test::Unit::TestCase
  def test_terminal?
    rule = Sequence.new
    assert_equal(false, rule.terminal?)
  end

  def test_exec
    a = Rule.for('a')
    b = Rule.for('b')
    c = Rule.for('c')
    rule = Sequence.new([ a, b, c ])

    events = rule.exec(Input.new(''))
    assert_equal([], events)

    expected_events = [
      rule,
        a, CLOSE, 1,
        b, CLOSE, 1,
        c, CLOSE, 1,
      CLOSE, 3
    ]

    events = rule.exec(Input.new('abc'))
    assert_equal(expected_events, events)
  end

  def test_to_s
    rule = Sequence.new(%w<a b>)
    assert_equal('"a" "b"', rule.to_s)
  end

  def test_to_s_embed
    rule1 = Sequence.new(%w<a b>)
    rule2 = Sequence.new(%w<c d>)
    rule = Sequence.new([rule1, rule2])
    assert_equal('("a" "b") ("c" "d")', rule.to_s)
  end
end
