require File.dirname(__FILE__) + '/helper'

class LabelTest < Test::Unit::TestCase

  def test_terminal?
    rule = Label.new
    assert_equal(false, rule.terminal?)
  end

  def test_match
    rule = Label.new('label', 'a')

    match = rule.match(input('a'))
    assert(match)
    assert_equal('label', match.name)
  end

  def test_to_s
    rule = Label.new('label', 'a')
    assert_equal('label:"a"', rule.to_s)

    rule = Label.new('label', Sequence.new(%w< a b >))
    assert_equal('label:("a" "b")', rule.to_s)
  end

end
