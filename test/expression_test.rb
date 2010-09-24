require File.expand_path('../helper', __FILE__)

class ExpressionTest < Test::Unit::TestCase

  def test_terminal?
    rule = Expression.new
    assert(rule.terminal?)
  end

  def test_match
    rule = Expression.new(/\d+/)
    match = rule.match(input('123 456'))
    assert(match)
    assert_equal('123', match)
    assert_equal(3, match.length)
  end

  def test_match_failure
    rule = Expression.new(/\d+/)
    match = rule.match(input(' 456'))
    assert_equal(nil, match)
  end

  def test_to_s
    rule = Expression.new(/\d+/)
    assert_equal('/\\d+/', rule.to_s)
  end

end
