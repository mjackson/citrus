require File.expand_path('../helper', __FILE__)

class InputTest < Test::Unit::TestCase

  def test_new_input
    input = Input.new("abc\ndef\nghi")
    assert_equal(0, input.line_offset)
    assert_equal(0, input.line_index)
    assert_equal(1, input.line_number)
    assert_equal("abc\n", input.line)
  end

  def test_advanced_input
    input = Input.new("abc\ndef\nghi")
    input.pos = 6
    assert_equal(2, input.line_offset)
    assert_equal(1, input.line_index)
    assert_equal(2, input.line_number)
    assert_equal("def\n", input.line)
  end

end
