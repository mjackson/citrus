require File.dirname(__FILE__) + '/helper'

class SequenceTest < Test::Unit::TestCase

  include Citrus

  def test_terminal?
    rule = Sequence.new([])
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Sequence.new(%w<a b>)

    input = Input.new('')
    match = rule.match(input)
    assert_equal(nil, match)

    input = Input.new('a')
    match = rule.match(input)
    assert_equal(nil, match)

    input = Input.new('ab')
    match = rule.match(input)
    assert(match)
    assert_equal('ab', match.value)
    assert_equal(2, match.length)

    assert(input.done?)
  end

  def test_to_s
    rule = Sequence.new(%w<a b>)
    assert_equal('"a" "b"', rule.to_s)

    rule1 = Sequence.new(%w<a b>)
    rule2 = Sequence.new(%w<c d>)
    rule = Sequence.new([rule1, rule2])
    assert_equal('("a" "b") ("c" "d")', rule.to_s)
  end

end
