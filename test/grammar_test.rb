require File.expand_path('../helper', __FILE__)

class GrammarTest < Test::Unit::TestCase
  def test_new
    grammar = Grammar.new
    assert_kind_of(Module, grammar)
    assert(grammar.include?(Grammar))
  end

  def test_name
    assert_equal("Test::Unit::TestCase::TestGrammar", TestGrammar.name)
  end

  def test_no_name
    grammar = Grammar.new
    assert_equal('', grammar.name)
  end

  def test_rule_names
    assert_equal([:alpha, :num, :alphanum], TestGrammar.rule_names)
  end

  def test_has_name
    assert(TestGrammar.has_rule?('alpha'))
    assert(TestGrammar.has_rule?(:alpha))
  end

  def test_doesnt_have_name
    assert_equal(false, TestGrammar.has_rule?(:value))
  end

  def test_parse_fixed_width
    grammar = Grammar.new {
      rule(:abc) { 'abc' }
    }
    match = grammar.parse('abc')
    assert(match)
    assert_equal('abc', match)
    assert_equal(3, match.length)
  end

  def test_parse_expression
    grammar = Grammar.new {
      rule(:alpha) { /[a-z]+/i }
    }
    match = grammar.parse('abc')
    assert(match)
    assert_equal('abc', match)
    assert_equal(3, match.length)
  end

  def test_parse_sequence
    grammar = Grammar.new {
      rule(:num) { all(1, 2, 3) }
    }
    match = grammar.parse('123')
    assert(match)
    assert_equal('123', match)
    assert_equal(3, match.length)
  end

  def test_parse_sequence_long
    grammar = Grammar.new {
      rule(:num) { all(1, 2, 3) }
    }
    match = grammar.parse('1234', :consume => false)
    assert(match)
    assert_equal('123', match)
    assert_equal(3, match.length)
  end

  def test_parse_sequence_short
    grammar = Grammar.new {
      rule(:num) { all(1, 2, 3) }
    }
    assert_raise ParseError do
      grammar.parse('12')
    end
  end

  def test_parse_choice
    grammar = Grammar.new {
      rule(:alphanum) { any(/[a-z]/i, 0..9) }
    }

    match = grammar.parse('a')
    assert(match)
    assert_equal('a', match)
    assert_equal(1, match.length)

    match = grammar.parse('1')
    assert(match)
    assert_equal('1', match)
    assert_equal(1, match.length)
  end

  def test_parse_choice_miss
    grammar = Grammar.new {
      rule(:alphanum) { any(/[a-z]/, 0..9) }
    }
    assert_raise ParseError do
      grammar.parse('A')
    end
  end

  def test_parse_recurs
    grammar = Grammar.new {
      rule(:paren) { any(['(', :paren, ')'], /[a-z]/) }
    }

    match = grammar.parse('a')
    assert(match)
    assert_equal('a', match)
    assert_equal(1, match.length)

    match = grammar.parse('((a))')
    assert(match)
    assert_equal('((a))', match)
    assert_equal(5, match.length)

    n = 100
    str = ('(' * n) + 'a' + (')' * n)
    match = grammar.parse(str)
    assert(match)
    assert_equal(str, match)
    assert_equal(str.length, match.length)
  end

  def test_parse_file
    grammar = Grammar.new {
      rule("words"){ rep(any(" ", /[a-z]+/)) }
    }

    require 'tempfile'
    Tempfile.open('citrus') do |tmp|
      tmp << "abd def"
      tmp.close

      match = grammar.parse_file(tmp.path)

      assert(match)
      assert_instance_of(Input, match.input)
      assert_instance_of(Pathname, match.source)

      match.matches.each do |m|
        assert_instance_of(Input, m.input)
        assert_instance_of(Pathname, m.source)
      end
    end
  end

  def test_labeled_production
    grammar = Grammar.new {
      rule(:abc) { label('abc', :p){ p } }
    }
    assert_equal('abc', grammar.parse('abc').value)
  end

  def test_global_grammar
    assert_raise ArgumentError do
      grammar(:abc)
    end
  end
end
