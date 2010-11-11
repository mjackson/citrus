require File.expand_path('../helper', __FILE__)

class ParseErrorTest < Test::Unit::TestCase
  Sentence = Grammar.new do
    include Words

    rule :sentence do
      all(:capital_word, one_or_more([ :space, :word ]), :period)
    end

    rule :capital_word do
      all(/[A-Z]/, zero_or_more(:alpha))
    end

    rule :space do
      one_or_more(any(" ", "\n", "\r\n"))
    end

    rule :period, '.'
  end

  def test_basic
    begin
      TestGrammar.parse('#')
    rescue ParseError => e
      assert_equal(0, e.offset)
      assert_equal('#', e.line)
      assert_equal(1, e.line_number)
      assert_equal(0, e.line_offset)
    end
  end

  def test_single_line
    begin
      Sentence.parse('Once upon 4 time.')
    rescue ParseError => e
      assert_equal(10, e.offset)
      assert_equal('Once upon 4 time.', e.line)
      assert_equal(1, e.line_number)
      assert_equal(10, e.line_offset)
    end
  end

  def test_multi_line
    begin
      Sentence.parse("Once\nupon a\r\ntim3.")
    rescue ParseError => e
      assert_equal(16, e.offset)
      assert_equal('tim3.', e.line)
      assert_equal(3, e.line_number)
      assert_equal(3, e.line_offset)
    end
  end
end
