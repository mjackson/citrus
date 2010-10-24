require File.expand_path('../helper', __FILE__)

# This file tests functionality that is only present when debugging is enabled.

class DebugTest < Test::Unit::TestCase

  def test_offset
    match = Words.parse('one two')
    assert(match)
    assert_equal(0, match.offset)

    words = match.find(:word)
    assert(match)
    assert_equal(2, words.length)

    assert_equal('one', words[0])
    assert_equal(0, words[0].offset)

    assert_equal('two', words[1])
    assert_equal(4, words[1].offset)
  end

end
