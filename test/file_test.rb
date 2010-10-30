require File.expand_path('../helper', __FILE__)
require 'citrus/file'

class CitrusFileTest < Test::Unit::TestCase

  # A shortcut for creating a grammar that includes Citrus::File but uses a
  # different root.
  def file(root_rule)
    Grammar.new do
      include Citrus::File
      root root_rule
    end
  end

  ## File tests

  def run_file_test(file, root)
    grammar = file(root)
    code = F.read(file)
    match = grammar.parse(code)
    assert(match)
  end

  %w< rule grammar >.each do |type|
    Dir[F.dirname(__FILE__) + "/_files/#{type}*.citrus"].each do |path|
      module_eval(<<-RUBY.gsub(/^        /, ''), __FILE__, __LINE__ + 1)
        def test_#{F.basename(path, '.citrus')}
          run_file_test("#{path}", :#{type})
        end
      RUBY
    end
  end

  ## Hierarchical syntax

  def test_rule_body
    grammar = file(:rule_body)

    match = grammar.parse('"a" | "b"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    match = grammar.parse('rule_name')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Alias, match.value)

    match = grammar.parse('""')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)

    match = grammar.parse('"a"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)

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
    assert_instance_of(Terminal, match.value)

    match = grammar.parse('[a-z]')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)

    match = grammar.parse('/./')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)

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
    assert_equal(0, match.find(:dot).length)

    match = grammar.parse('"" {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)

    match = grammar.parse('""* {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)

    match = grammar.parse('"a"*')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
    assert_equal(0, match.value.min)
    assert_equal(Infinity, match.value.max)

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
    assert_instance_of(Terminal, match.value)

    match = grammar.parse("[0-9]+ {\n  def value\n    text.to_i\n  end\n}\n")
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_precedence
    grammar = file(:rule_body)

    # Sequence should bind more tightly than Choice.
    match = grammar.parse('"a" "b" | "c"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)

    # Parentheses should change binding precedence.
    match = grammar.parse('"a" ("b" | "c")')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)

    # Repeat should bind more tightly than AndPredicate.
    match = grammar.parse("&'a'+")
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(AndPredicate, match.value)
  end

  def test_empty
    grammar = file(:rule_body)

    match = grammar.parse('')
    assert(match)
  end

  def test_choice
    grammar = file(:choice)

    match = grammar.parse('"a" | "b"')
    assert(match)
    assert_equal(2, match.rules.length)
    assert_instance_of(Choice, match.value)

    match = grammar.parse('"a" | ("b" "c")')
    assert(match)
    assert_equal(2, match.rules.length)
    assert_instance_of(Choice, match.value)
  end

  def test_sequence
    grammar = file(:sequence)

    match = grammar.parse('"" ""')
    assert(match)
    assert_equal(2, match.rules.length)
    assert_instance_of(Sequence, match.value)

    match = grammar.parse('"a" "b" "c"')
    assert(match)
    assert_equal(3, match.rules.length)
    assert_instance_of(Sequence, match.value)
  end

  def test_expression
    grammar = file(:expression)

    match = grammar.parse('"" <Module>')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.extension)

    match = grammar.parse('"" {}')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.extension)

    match = grammar.parse('"" {} ')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.extension)
  end

  def test_prefix
    grammar = file(:prefix)

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

  def test_suffix
    grammar = file(:suffix)

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
    grammar = file(:primary)

    match = grammar.parse('rule_name')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Alias, match.value)

    match = grammar.parse('"a"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
  end


  ## Lexical syntax


  def test_require
    grammar = file(:require)

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
    grammar = file(:include)

    match = grammar.parse('include Module')
    assert(match)
    assert_equal(Module, match.value)

    match = grammar.parse('include ::Module')
    assert(match)
    assert_equal(Module, match.value)
  end

  def test_root
    grammar = file(:root)

    match = grammar.parse('root some_rule')
    assert(match)
    assert_equal('some_rule', match.value)

    assert_raise ParseError do
      match = grammar.parse('root :a_root')
    end
  end

  def test_rule_name
    grammar = file(:rule_name)

    match = grammar.parse('some_rule')
    assert(match)
    assert('some_rule', match.value)

    match = grammar.parse('some_rule ')
    assert(match)
    assert('some_rule', match.value)
  end

  def test_terminal
    grammar = file(:terminal)

    match = grammar.parse('"a"')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
    assert(match.value.terminal?)

    match = grammar.parse('[a-z]')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
    assert(match.value.terminal?)

    match = grammar.parse('.')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
    assert(match.value.terminal?)

    match = grammar.parse('/./')
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
    assert(match.value.terminal?)
  end

  def test_single_quoted_string
    grammar = file(:quoted_string)

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
    grammar = file(:quoted_string)

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
    grammar = file(:character_class)

    match = grammar.parse('[_]')
    assert(match)
    assert_equal(/\A[_]/, match.value)

    match = grammar.parse('[a-z]')
    assert(match)
    assert_equal(/\A[a-z]/, match.value)

    match = grammar.parse('[a-z0-9]')
    assert(match)
    assert_equal(/\A[a-z0-9]/, match.value)

    match = grammar.parse('[\[-\]]')
    assert(match)
    assert_equal(/\A[\[-\]]/, match.value)

    match = grammar.parse('[\\x26-\\x29]')
    assert(match)
    assert_equal(/\A[\x26-\x29]/, match.value)
  end

  def test_dot
    grammar = file(:dot)

    match = grammar.parse('.')
    assert(match)
    assert_equal(DOT, match.value)
  end

  def test_regular_expression
    grammar = file(:regular_expression)

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

  def test_predicate
    grammar = file(:predicate)

    match = grammar.parse('&')
    assert(match)
    assert_kind_of(Rule, match.value(''))

    match = grammar.parse('!')
    assert(match)
    assert_kind_of(Rule, match.value(''))
  end

  def test_and
    grammar = file(:and)

    match = grammar.parse('&')
    assert(match)
    assert_instance_of(AndPredicate, match.value(''))

    match = grammar.parse('& ')
    assert(match)
    assert_instance_of(AndPredicate, match.value(''))
  end

  def test_not
    grammar = file(:not)

    match = grammar.parse('!')
    assert(match)
    assert_instance_of(NotPredicate, match.value(''))

    match = grammar.parse('! ')
    assert(match)
    assert_instance_of(NotPredicate, match.value(''))
  end

  def test_label
    grammar = file(:label)

    match = grammar.parse('label:')
    assert(match)
    v = match.value('')
    assert_instance_of(Label, v)
    assert_equal(:label, v.label)

    match = grammar.parse('a_label : ')
    assert(match)
    v = match.value('')
    assert_instance_of(Label, v)
    assert_equal(:a_label, v.label)
  end

  def test_tag
    grammar = file(:tag)

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
    grammar = file(:block)

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

  def test_block_with_interpolation
    grammar = file(:block)

    match = grammar.parse('{ "#{number}" }')
    assert(match)
    assert(match.value)
  end

  def test_repeat
    grammar = file(:repeat)

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
    grammar = file(:question)

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
    grammar = file(:plus)

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
    grammar = file(:repeat)

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
    grammar = file(:module_name)

    match = grammar.parse('Module')
    assert(match)

    match = grammar.parse('::Proc')
    assert(match)
  end

  def test_constant
    grammar = file(:constant)

    match = grammar.parse('Math')
    assert(match)

    assert_raise ParseError do
      match = grammar.parse('math')
    end
  end

  def test_comment
    grammar = file(:comment)

    match = grammar.parse('# A comment.')
    assert(match)
    assert_equal('# A comment.', match)
  end

end
