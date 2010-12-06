require File.expand_path('../helper', __FILE__)

class ChoiceTest < Test::Unit::TestCase
  def test_terminal?
    rule = Choice.new
    assert_equal(false, rule.terminal?)
  end

  def test_exec
    a = Rule.for('a')
    b = Rule.for('b')
    rule = Choice.new([ a, b ])

    events = rule.exec(Input.new(''))
    assert_equal([], events)

    events = rule.exec(Input.new('a'))
    assert(events)
    assert_equal([rule.id, a.id, CLOSE, 1, CLOSE, 1], events)

    events = rule.exec(Input.new('b'))
    assert(events)
    assert_equal([rule.id, b.id, CLOSE, 1, CLOSE, 1], events)
  end

  def test_to_s
    rule = Choice.new(%w<a b>)
    assert_equal('"a" | "b"', rule.to_s)
  end

  def test_to_s_embed
    rule1 = Choice.new(%w<a b>)
    rule2 = Choice.new(%w<c d>)
    rule = Choice.new([rule1, rule2])
    assert_equal('("a" | "b") | ("c" | "d")', rule.to_s)
  end
end
