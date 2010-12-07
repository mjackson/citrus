require File.expand_path('../helper', __FILE__)

class NotPredicateTest < Test::Unit::TestCase
  def test_terminal?
    rule = NotPredicate.new
    assert_equal(false, rule.terminal?)
  end

  def test_exec
    rule = NotPredicate.new('abc')
    events = rule.exec(Input.new('def'))
    assert_equal([rule, CLOSE, 0], events)
  end

  def test_exec_miss
    rule = NotPredicate.new('abc')
    events = rule.exec(Input.new('abc'))
    assert_equal([], events)
  end

  def test_consumption
    rule = NotPredicate.new('abc')
    input = Input.new('def')
    events = rule.exec(input)
    assert_equal(0, input.pos)
  end

  def test_to_s
    rule = NotPredicate.new('a')
    assert_equal('!"a"', rule.to_s)
  end

  def test_to_s_with_label
    rule = NotPredicate.new('a')
    rule.label = 'a_label'
    assert_equal('a_label:!"a"', rule.to_s)
  end
end
