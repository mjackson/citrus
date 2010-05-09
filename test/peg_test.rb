require File.dirname(__FILE__) + '/helper'
require 'citrus/peg'

class PEGTest < Test::Unit::TestCase

  # A shortcut for creating a grammar that includes Citrus::PEG but uses a
  # different root.
  def peg(root_rule)
    Grammar.new {
      include Citrus::PEG
      root root_rule
    }
  end


  ## File tests


  def run_file_test(file, root)
    grammar = peg(root)
    code = File.read(file)
    match = grammar.parse(code)
    assert(match)
  end

  %w< rule grammar >.each do |type|
    Dir[File.dirname(__FILE__) + "/_files/#{type}*.citrus"].each do |path|
      module_eval(<<-RUBY.gsub(/^        /, ''), __FILE__, __LINE__ + 1)
        def test_#{File.basename(path, '.citrus')}
          run_file_test("#{path}", :#{type})
        end
      RUBY
    end
  end


  ## Hierarchical syntax


  def test_rule_body
    grammar = peg(:rule_body)

    match = grammar.parse('"a" | "b"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    match = grammar.parse('rule_name')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Proxy, match.value)

    match = grammar.parse('""')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(FixedWidth, match.value)

    match = grammar.parse('"a"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(FixedWidth, match.value)

    match = grammar.parse('"a" "b"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)

    match = grammar.parse('"a" | "b"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    match = grammar.parse('.')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Expression, match.value)

    match = grammar.parse('[a-z]')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Expression, match.value)

    match = grammar.parse('/./')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Expression, match.value)

    match = grammar.parse('/./ /./')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
    assert_equal(2, match.find(:regular_expression).length)

    match = grammar.parse('/./ | /./')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)
    assert_equal(1, match.find(:bar).length)
    assert_equal(2, match.find(:regular_expression).length)
    assert_equal(0, match.find(:anything_symbol).length)

    match = grammar.parse('"" {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(FixedWidth, match.value)

    match = grammar.parse('""* {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('("a" "b")*')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('"a" | "b"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    match = grammar.parse('("a" | "b")*')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('("a" "b")* {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('("a" | "b")* {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('("a" | /./)')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    # Test precedence of Sequence over Choice.
    match = grammar.parse('"a" "b" | "c"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    match = grammar.parse('"a" ("b" | /./)* {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)

    match = grammar.parse('("a" "b")* <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('( "a" "b" )* <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('( "a" "b" ) <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)

    match = grammar.parse('("a" | "b")* <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('("a" | "b") <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    match = grammar.parse('"a" ("b" | /./)* <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)

    match = grammar.parse("[0-9] {\n  def value\n    text.to_i\n  end\n}\n")
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Expression, match.value)

    match = grammar.parse("[0-9]+ {\n  def value\n    text.to_i\n  end\n}\n")
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_sequence
    grammar = peg(:sequence)

    match = grammar.parse('"" ""')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)

    match = grammar.parse('"a" "b" "c"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
  end

  def test_prefix
    grammar = peg(:prefix)

    match = grammar.parse('&""')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(AndPredicate, match.value)

    match = grammar.parse('!""')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(NotPredicate, match.value)

    match = grammar.parse('label:""')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Label, match.value)

    match = grammar.parse('label :"" ')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Label, match.value)
  end

  def test_appendix
    grammar = peg(:appendix)

    match = grammar.parse('"" <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.match_module)

    match = grammar.parse('"" {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.match_module)

    match = grammar.parse('"" {} ')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.match_module)
  end

  def test_suffix
    grammar = peg(:suffix)

    match = grammar.parse('""+')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('""? ')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('""1* ')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_primary
    grammar = peg(:primary)

    match = grammar.parse('rule_name')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Proxy, match.value)

    match = grammar.parse('"a"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(FixedWidth, match.value)
  end


  ## Lexical syntax


  def test_require
    grammar = peg(:require)

    match = grammar.parse('require "some/file"')
    assert(match)
    assert_equal('some/file', match.value)

    match = grammar.parse('require"some/file"')
    assert(match)
    assert_equal('some/file', match.value)

    match = grammar.parse("require 'some/file'")
    assert(match)
    assert_equal('some/file', match.value)
  end

  def test_include
    grammar = peg(:include)

    match = grammar.parse('include Module')
    assert(match)
    assert_equal('Module', match.value)

    match = grammar.parse('include ::Module')
    assert(match)
    assert_equal('::Module', match.value)
  end

  def test_root
    grammar = peg(:root)

    match = grammar.parse('root some_rule')
    assert(match)
    assert_equal('some_rule', match.value)

    assert_raise ParseError do
      match = grammar.parse('root :a_root')
    end
  end

  def test_rule_name
    grammar = peg(:rule_name)

    match = grammar.parse('some_rule')
    assert(match)
    assert('some_rule', match.value)

    match = grammar.parse('some_rule ')
    assert(match)
    assert('some_rule', match.value)
  end

  def test_proxy
    grammar = peg(:proxy)

    match = grammar.parse('some_rule')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Proxy, match.value)

    match = grammar.parse('some_rule ')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Proxy, match.value)
  end

  def test_terminal
    grammar = peg(:terminal)

    match = grammar.parse('"a"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(FixedWidth, match.value)
    assert(match.value.terminal?)

    match = grammar.parse('[a-z]')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Expression, match.value)
    assert(match.value.terminal?)

    match = grammar.parse('.')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Expression, match.value)
    assert(match.value.terminal?)

    match = grammar.parse('/./')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Expression, match.value)
    assert(match.value.terminal?)
  end

  def test_single_quoted_string
    grammar = peg(:quoted_string)

    match = grammar.parse("'test'")
    assert(match)
    assert_equal('test', match.value)

    match = grammar.parse("'te\\'st'")
    assert(match)
    assert_equal("te'st", match.value)

    match = grammar.parse("'te\"st'")
    assert(match)
    assert_equal('te"st', match.value)
  end

  def test_double_quoted_string
    grammar = peg(:quoted_string)

    match = grammar.parse('"test"')
    assert(match)
    assert_equal('test', match.value)

    match = grammar.parse('"te\\"st"')
    assert(match)
    assert_equal('te"st', match.value)

    match = grammar.parse('"te\'st"')
    assert(match)
    assert_equal("te'st", match.value)

    match = grammar.parse('"\\x26"')
    assert(match)
    assert_equal('&', match.value)
  end

  def test_character_class
    grammar = peg(:character_class)

    match = grammar.parse('[_]')
    assert(match)
    assert_equal(/[_]/, match.value)

    match = grammar.parse('[a-z]')
    assert(match)
    assert_equal(/[a-z]/, match.value)

    match = grammar.parse('[a-z0-9]')
    assert(match)
    assert_equal(/[a-z0-9]/, match.value)

    match = grammar.parse('[\\x26-\\x29]')
    assert(match)
    assert_equal(/[\x26-\x29]/, match.value)
  end

  def test_anything_symbol
    grammar = peg(:anything_symbol)

    match = grammar.parse('.')
    assert(match)
    assert_equal(/./m, match.value)
  end

  def test_regular_expression
    grammar = peg(:regular_expression)

    match = grammar.parse('/./')
    assert(match)
    assert_equal(/./, match.value)

    match = grammar.parse('/\\//')
    assert(match)
    assert_equal(/\//, match.value)

    match = grammar.parse('/\\\\/')
    assert(match)
    assert_equal(/\\/, match.value)

    match = grammar.parse('/\\x26/')
    assert(match)
    assert_equal(/\x26/, match.value)

    match = grammar.parse('/a/i')
    assert(match)
    assert_equal(/a/i, match.value)
  end

  def test_qualifier
    grammar = peg(:qualifier)

    match = grammar.parse('&')
    assert(match)
    assert_kind_of(Rule, match.wrap(''))

    match = grammar.parse('!')
    assert(match)
    assert_kind_of(Rule, match.wrap(''))
  end

  def test_and
    grammar = peg(:and)

    match = grammar.parse('&')
    assert(match)
    assert_instance_of(AndPredicate, match.wrap(''))

    match = grammar.parse('& ')
    assert(match)
    assert_instance_of(AndPredicate, match.wrap(''))
  end

  def test_not
    grammar = peg(:not)

    match = grammar.parse('!')
    assert(match)
    assert_instance_of(NotPredicate, match.wrap(''))

    match = grammar.parse('! ')
    assert(match)
    assert_instance_of(NotPredicate, match.wrap(''))
  end

  def test_label
    grammar = peg(:label)

    match = grammar.parse('label:')
    assert(match)
    assert_equal('label', match.value)
    assert_instance_of(Label, match.wrap(''))

    match = grammar.parse('a_label : ')
    assert(match)
    assert_equal('a_label', match.value)
    assert_instance_of(Label, match.wrap(''))
  end

  def test_tag
    grammar = peg(:tag)

    match = grammar.parse('<Module>')
    assert(match)
    assert_equal(Module, match.value)

    match = grammar.parse('< Module >')
    assert(match)
    assert_equal(Module, match.value)

    match = grammar.parse('<Module> ')
    assert(match)
    assert_equal(Module, match.value)
  end

  def test_block
    grammar = peg(:block)

    match = grammar.parse('{}')
    assert(match)
    assert(match.value)

    match = grammar.parse("{} \n")
    assert(match)
    assert(match.value)

    match = grammar.parse('{ 2 }')
    assert(match)
    assert(match.value)
    assert_equal(2, match.value.call)

    match = grammar.parse("{ {:a => :b}\n}")
    assert(match)
    assert(match.value)
    assert_equal({:a => :b}, match.value.call)

    match = grammar.parse("{|b|\n  Proc.new(&b)\n}")
    assert(match)
    assert(match.value)

    b = match.value.call(Proc.new { :hi })

    assert(b)
    assert_equal(:hi, b.call)

    match = grammar.parse("{\n  def value\n    'a'\n  end\n} ")
    assert(match)
    assert(match.value)
  end

  def test_quantifier
    grammar = peg(:quantifier)

    match = grammar.parse('?')
    assert(match)
    assert_instance_of(Repeat, match.wrap(''))

    match = grammar.parse('+')
    assert(match)
    assert_instance_of(Repeat, match.wrap(''))

    match = grammar.parse('*')
    assert(match)
    assert_instance_of(Repeat, match.wrap(''))
  end

  def test_question
    grammar = peg(:question)

    match = grammar.parse('?')
    assert(match)
    assert_equal(0, match.min)
    assert_equal(1, match.max)

    match = grammar.parse('? ')
    assert(match)
    assert_equal(0, match.min)
    assert_equal(1, match.max)
  end

  def test_plus
    grammar = peg(:plus)

    match = grammar.parse('+')
    assert(match)
    assert_equal(1, match.min)
    assert_equal(Infinity, match.max)

    match = grammar.parse('+ ')
    assert(match)
    assert_equal(1, match.min)
    assert_equal(Infinity, match.max)
  end

  def test_repeat
    grammar = peg(:repeat)

    match = grammar.parse('*')
    assert(match)
    assert_equal(0, match.min)
    assert_equal(Infinity, match.max)

    match = grammar.parse('1*')
    assert(match)
    assert_equal(1, match.min)
    assert_equal(Infinity, match.max)

    match = grammar.parse('*2')
    assert(match)
    assert_equal(0, match.min)
    assert_equal(2, match.max)

    match = grammar.parse('1*2')
    assert(match)
    assert_equal(1, match.min)
    assert_equal(2, match.max)

    match = grammar.parse('1*2 ')
    assert(match)
    assert_equal(1, match.min)
    assert_equal(2, match.max)
  end

  def test_module_name
    grammar = peg(:module_name)

    match = grammar.parse('Module')
    assert(match)

    match = grammar.parse('::Proc')
    assert(match)
  end

  def test_constant
    grammar = peg(:constant)

    match = grammar.parse('Math')
    assert(match)

    assert_raise ParseError do
      match = grammar.parse('math')
    end
  end

  def test_comment
    grammar = peg(:comment)

    match = grammar.parse('# A comment.')
    assert(match)
    assert_equal('# A comment.', match.text)

    assert_raise ParseError do
      match = grammar.parse("# A comment.\n")
    end
  end

end
