require File.dirname(__FILE__) + '/helper'

class MatchTest < Test::Unit::TestCase

  include Citrus

  def test_all
    match = Match.new('0')
    assert_equal('0', match.value)
    assert_equal(1, match.length)

    match = Match.new('hello')
    assert_equal('hello', match.value)
    assert_equal(5, match.length)

    match = Match.new('hello world'.match(/^(\w+) /))
    assert_equal('hello ', match.value)
    assert_equal(6, match.length)

    match1 = Match.new('hello')
    match2 = Match.new(' world'.match(/.+/))
    match = Match.new([match1, match2])
    assert_equal('hello world', match.value)
    assert_equal(11, match.length)
  end

end
