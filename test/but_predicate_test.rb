require File.expand_path('../helper', __FILE__)

class ButPredicateTest < Test::Unit::TestCase
  def test_terminal?
    rule = ButPredicate.new
    assert_equal(false, rule.terminal?)
  end

  def test_exec
    rule = ButPredicate.new('abc')

    events = rule.exec(Input.new('def'))
    assert_equal([rule, CLOSE, 3], events)

    events = rule.exec(Input.new('defabc'))
    assert_equal([rule, CLOSE, 3], events)
  end

  def test_exec_miss
    rule = ButPredicate.new('abc')
    events = rule.exec(Input.new('abc'))
    assert_equal([], events)
  end

  def test_consumption
    rule = ButPredicate.new('abc')

    input = Input.new('def')
    events = rule.exec(input)
    assert_equal(3, input.pos)

    input = Input.new('defabc')
    events = rule.exec(input)
    assert_equal(3, input.pos)
  end

  def test_to_s
    rule = ButPredicate.new('a')
    assert_equal('~"a"', rule.to_s)
  end
end