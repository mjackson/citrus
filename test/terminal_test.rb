require File.expand_path('../helper', __FILE__)

class TerminalTest < Test::Unit::TestCase
  def test_terminal?
    rule = Terminal.new
    assert(rule.terminal?)
  end

  def test_exec
    rule = Terminal.new(/\d+/)
    events = rule.exec(Input.new('123'))
    assert_equal([rule, CLOSE, 3], events)
  end

  def test_exec_long
    rule = Terminal.new(/\d+/)
    events = rule.exec(Input.new('123 456'))
    assert_equal([rule, CLOSE, 3], events)
  end

  def test_exec_miss
    rule = Terminal.new(/\d+/)
    events = rule.exec(Input.new(' 123'))
    assert_equal([], events)
  end

  def test_to_s
    rule = Terminal.new(/\d+/)
    assert_equal('/\\d+/', rule.to_s)
  end
end
