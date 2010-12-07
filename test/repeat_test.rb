require File.expand_path('../helper', __FILE__)

class RepeatTest < Test::Unit::TestCase
  def test_terminal?
    rule = Repeat.new
    assert_equal(false, rule.terminal?)
  end

  def test_exec_zero_or_one
    abc = Rule.for('abc')
    rule = Repeat.new(abc, 0, 1)

    events = rule.exec(Input.new(''))
    assert_equal([rule, CLOSE, 0], events)

    events = rule.exec(Input.new('abc'))
    assert_equal([rule, abc, CLOSE, 3, CLOSE, 3], events)

    events = rule.exec(Input.new('abc' * 3))
    assert_equal([rule, abc, CLOSE, 3, CLOSE, 3], events)
  end

  def test_exec_zero_or_more
    abc = Rule.for('abc')
    rule = Repeat.new(abc, 0, Infinity)

    events = rule.exec(Input.new(''))
    assert_equal([rule, CLOSE, 0], events)

    events = rule.exec(Input.new('abc'))
    assert_equal([rule, abc, CLOSE, 3, CLOSE, 3], events)

    expected_events = [
      rule,
        abc, CLOSE, 3,
        abc, CLOSE, 3,
        abc, CLOSE, 3,
      CLOSE, 9
    ]

    events = rule.exec(Input.new('abc' * 3))
    assert_equal(expected_events, events)
  end

  def test_exec_one_or_more
    abc = Rule.for('abc')
    rule = Repeat.new(abc, 1, Infinity)

    events = rule.exec(Input.new(''))
    assert_equal([], events)

    events = rule.exec(Input.new('abc'))
    assert_equal([rule, abc, CLOSE, 3, CLOSE, 3], events)

    expected_events = [
      rule,
        abc, CLOSE, 3,
        abc, CLOSE, 3,
        abc, CLOSE, 3,
      CLOSE, 9
    ]

    events = rule.exec(Input.new('abc' * 3))
    assert_equal(expected_events, events)
  end

  def test_exec_one
    abc = Rule.for('abc')
    rule = Repeat.new(abc, 1, 1)

    events = rule.exec(Input.new(''))
    assert_equal([], events)

    events = rule.exec(Input.new('abc'))
    assert_equal([rule, abc, CLOSE, 3, CLOSE, 3], events)

    events = rule.exec(Input.new('abc' * 3))
    assert_equal([rule, abc, CLOSE, 3, CLOSE, 3], events)
  end

  def test_operator
    rule = Repeat.new('', 1, 2)
    assert_equal('1*2', rule.operator)
  end

  def test_operator_empty
    rule = Repeat.new('', 0, 0)
    assert_equal('', rule.operator)
  end

  def test_operator_asterisk
    rule = Repeat.new('', 0, Infinity)
    assert_equal('*', rule.operator)
  end

  def test_operator_question_mark
    rule = Repeat.new('', 0, 1)
    assert_equal('?', rule.operator)
  end

  def test_operator_plus
    rule = Repeat.new('', 1, Infinity)
    assert_equal('+', rule.operator)
  end

  def test_to_s
    rule = Repeat.new(/a/, 1, 2)
    assert_equal('/a/1*2', rule.to_s)
  end

  def test_to_s_asterisk
    rule = Repeat.new('a', 0, Infinity)
    assert_equal('"a"*', rule.to_s)
  end

  def test_to_s_question_mark
    rule = Repeat.new('a', 0, 1)
    assert_equal('"a"?', rule.to_s)
  end

  def test_to_s_plus
    rule = Repeat.new('a', 1, Infinity)
    assert_equal('"a"+', rule.to_s)
  end
end
