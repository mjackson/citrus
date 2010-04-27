require File.dirname(__FILE__) + '/helper'

class GrammarTest < Test::Unit::TestCase

  include Citrus

  def test_parse_fixed_width
    grammar = Class.new(Grammar)
    grammar.rule(:abc, 'abc')

    match = grammar.parse('abc')
    assert(match)
    assert_equal('abc', match.value)
    assert_equal(3, match.length)
  end

  def test_parse_expression
    grammar = Class.new(Grammar)
    grammar.rule(:alpha, /[a-z]+/i)

    match = grammar.parse('abc')
    assert(match)
    assert_equal('abc', match.value)
    assert_equal(3, match.length)
  end

  def test_parse_sequence
    grammar = Class.new(Grammar)
    grammar.rule(:num, grammar.sequence(1, 2, 3))

    match = grammar.parse('1')
    assert_equal(nil, match)

    match = grammar.parse('123')
    assert(match)
    assert_equal('123', match.value)
    assert_equal(3, match.length)
  end

  def test_parse_choice
    grammar = Class.new(Grammar)
    grammar.rule(:alphanum, grammar.choice(/[a-z]/i, 0..9))

    match = grammar.parse('a')
    assert(match)
    assert_equal('a', match.value)
    assert_equal(1, match.length)

    match = grammar.parse('1')
    assert(match)
    assert_equal('1', match.value)
    assert_equal(1, match.length)
  end

  def test_match_recurs
    input = Input.new('((a))')
    rule = Choice.new([ /[a-z]/ ])
    rule.rules.unshift(Sequence.new(['(', rule, ')']))

    match = rule.match(input)
    assert(match)
    assert('((a))', match.value)
    assert(5, match.length)
    assert(input.done?)
  end

  def test_parse_recurs
    grammar = Class.new(Grammar)
    grammar.rule(:paren, grammar.choice(['(', :paren, ')'], /[a-z]/))
    match = grammar.parse('((a))')
    assert(match)
    assert_equal('((a))', match.value)
    assert_equal(5, match.length)
  end

end
