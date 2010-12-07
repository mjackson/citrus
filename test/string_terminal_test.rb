require File.expand_path('../helper', __FILE__)

class StringTerminalTest < Test::Unit::TestCase
  def test_terminal?
    rule = StringTerminal.new
    assert(rule.terminal?)
  end

  def test_exec
    rule = StringTerminal.new('abc')
    events = rule.exec(Input.new('abc'))
    assert_equal([rule, CLOSE, 3], events)
  end

  def test_exec_miss
    rule = StringTerminal.new('abc')
    events = rule.exec(Input.new('def'))
    assert_equal([], events)
  end

  def test_exec_short
    rule = StringTerminal.new('abc')
    events = rule.exec(Input.new('ab'))
    assert_equal([], events)
  end

  def test_exec_long
    rule = StringTerminal.new('abc')
    events = rule.exec(Input.new('abcd'))
    assert_equal([rule, CLOSE, 3], events)
  end

  def test_exec_case_insensitive
    rule = StringTerminal.new('abc', Regexp::IGNORECASE)

    events = rule.exec(Input.new('abc'))
    assert_equal([rule, CLOSE, 3], events)

    events = rule.exec(Input.new('ABC'))
    assert_equal([rule, CLOSE, 3], events)

    events = rule.exec(Input.new('Abc'))
    assert_equal([rule, CLOSE, 3], events)
  end

  def test_to_s
    rule = StringTerminal.new('abc')
    assert_equal('"abc"', rule.to_s)
  end

  def test_to_s_case_insensitive
    rule = StringTerminal.new('abc', Regexp::IGNORECASE)
    assert_equal('`abc`', rule.to_s)
  end
end
