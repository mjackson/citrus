require File.expand_path('../helper', __FILE__)

class CitrusFileTest < Test::Unit::TestCase

  ## File tests

  def run_file_test(file, root)
    match = File.parse(::File.read(file), :root => root)
    assert(match)
  end

  %w<rule grammar>.each do |type|
    Dir[::File.dirname(__FILE__) + "/_files/#{type}*.citrus"].each do |path|
      module_eval(<<-CODE.gsub(/^        /, ''), __FILE__, __LINE__ + 1)
        def test_#{::File.basename(path, '.citrus')}
          run_file_test("#{path}", :#{type})
        end
      CODE
    end
  end

  ## Hierarchical syntax

  def test_rule_body_alias
    match = File.parse('rule_name', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Alias, match.value)
  end

  def test_rule_body_dot
    match = File.parse('.', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
  end

  def test_rule_body_character_range
    match = File.parse('[a-z]', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
  end

  def test_rule_body_terminal
    match = File.parse('/./', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
  end

  def test_rule_body_string_terminal_empty
    match = File.parse('""', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_rule_body_string_terminal
    match = File.parse('"a"', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_rule_body_string_terminal_empty_block
    match = File.parse('"" {}', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_rule_body_repeat_string_terminal
    match = File.parse('"a"*', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_empty_string_terminal_block
    match = File.parse('""* {}', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_sequence
    match = File.parse('("a" "b")*', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_choice
    match = File.parse('("a" | "b")*', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_sequence_block
    match = File.parse('("a" "b")* {}', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_choice_block
    match = File.parse('("a" | "b")* {}', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_sequence_extension
    match = File.parse('("a" "b")* <Module>', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_sequence_extension_spaced
    match = File.parse('( "a" "b" )* <Module>', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_repeat_choice_extension
    match = File.parse('("a" | "b")* <Module>', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_rule_body_choice_terminal
    match = File.parse('/./ | /./', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)
  end

  def test_rule_body_choice_string_terminal
    match = File.parse('"a" | "b"', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)
  end

  def test_rule_body_choice_mixed
    match = File.parse('("a" | /./)', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)
  end

  def test_rule_body_choice_extended
    match = File.parse('("a" | "b") <Module>', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)
  end

  def test_rule_body_sequence_terminal
    match = File.parse('/./ /./', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
  end

  def test_rule_body_sequence_string_terminal
    match = File.parse('"a" "b"', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
  end

  def test_rule_body_sequence_extension
    match = File.parse('( "a" "b" ) <Module>', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
  end

  def test_rule_body_sequence_mixed
    match = File.parse('"a" ("b" | /./)* <Module>', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
  end

  def test_rule_body_sequence_block
    match = File.parse('"a" ("b" | /./)* {}', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
  end

  def test_precedence_sequence_before_choice
    # Sequence should bind more tightly than Choice.
    match = File.parse('"a" "b" | "c"', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Choice, match.value)
  end

  def test_precedence_parentheses
    # Parentheses should change binding precedence.
    match = File.parse('"a" ("b" | "c")', :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Sequence, match.value)
  end

  def test_precedence_repeat_before_predicate
    # Repeat should bind more tightly than AndPredicate.
    match = File.parse("&'a'+", :root => :rule_body)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(AndPredicate, match.value)
  end

  def test_rule_body_empty
    match = File.parse('', :root => :rule_body)
    assert(match)
  end

  def test_choice
    match = File.parse('"a" | "b"', :root => :choice)
    assert(match)
    assert_equal(2, match.rules.length)
    assert_instance_of(Choice, match.value)
  end

  def test_choice_embedded_sequence
    match = File.parse('"a" | ("b" "c")', :root => :choice)
    assert(match)
    assert_equal(2, match.rules.length)
    assert_instance_of(Choice, match.value)
  end

  def test_sequence
    match = File.parse('"" ""', :root => :sequence)
    assert(match)
    assert_equal(2, match.rules.length)
    assert_instance_of(Sequence, match.value)
  end

  def test_sequence_embedded_choice
    match = File.parse('"a" ("b" | "c")', :root => :sequence)
    assert(match)
    assert_equal(2, match.rules.length)
    assert_instance_of(Sequence, match.value)
  end

  def test_label_expression
    match = File.parse('label:""', :root => :label_expression)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_label_expression_space
    match = File.parse('label :"" ', :root => :label_expression)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_expression_tag
    match = File.parse('"" <Module>', :root => :expression)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.extension)
  end

  def test_expression_block
    match = File.parse('"" {}', :root => :expression)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.extension)
  end

  def test_expression_block_space
    match = File.parse('"" {} ', :root => :expression)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_kind_of(Module, match.value.extension)
  end

  def test_prefix_and
    match = File.parse('&""', :root => :prefix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(AndPredicate, match.value)
  end

  def test_prefix_not
    match = File.parse('!""', :root => :prefix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(NotPredicate, match.value)
  end

  def test_prefix_but
    match = File.parse('~""', :root => :prefix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(ButPredicate, match.value)
  end

  def test_suffix_plus
    match = File.parse('""+', :root => :suffix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_suffix_question
    match = File.parse('""? ', :root => :suffix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_suffix_star
    match = File.parse('""*', :root => :suffix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_suffix_n_star
    match = File.parse('""1*', :root => :suffix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_suffix_star_n
    match = File.parse('""*2', :root => :suffix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_suffix_n_star_n
    match = File.parse('""1*2', :root => :suffix)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Repeat, match.value)
  end

  def test_primary_alias
    match = File.parse('rule_name', :root => :primary)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Alias, match.value)
  end

  def test_primary_string_terminal
    match = File.parse('"a"', :root => :primary)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end


  ## Lexical syntax


  def test_require
    match = File.parse('require "some/file"', :root => :require)
    assert(match)
    assert_equal('some/file', match.value)
  end

  def test_require_no_space
    match = File.parse('require"some/file"', :root => :require)
    assert(match)
    assert_equal('some/file', match.value)
  end

  def test_require_single_quoted
    match = File.parse("require 'some/file'", :root => :require)
    assert(match)
    assert_equal('some/file', match.value)
  end

  def test_include
    match = File.parse('include Module', :root => :include)
    assert(match)
    assert_equal(Module, match.value)
  end

  def test_include_colon_colon
    match = File.parse('include ::Module', :root => :include)
    assert(match)
    assert_equal(Module, match.value)
  end

  def test_root
    match = File.parse('root some_rule', :root => :root)
    assert(match)
    assert_equal('some_rule', match.value)
  end

  def test_root_invalid
    assert_raise ParseError do
      File.parse('root :a_root', :root => :root)
    end
  end

  def test_rule_name
    match = File.parse('some_rule', :root => :rule_name)
    assert(match)
    assert('some_rule', match.value)
  end

  def test_rule_name_space
    match = File.parse('some_rule ', :root => :rule_name)
    assert(match)
    assert('some_rule', match.value)
  end

  def test_terminal_character_class
    match = File.parse('[a-z]', :root => :terminal)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
  end

  def test_terminal_dot
    match = File.parse('.', :root => :terminal)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
  end

  def test_terminal_regular_expression
    match = File.parse('/./', :root => :terminal)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(Terminal, match.value)
  end

  def test_string_terminal_single_quoted
    match = File.parse("'a'", :root => :string_terminal)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_string_terminal_double_quoted
    match = File.parse('"a"', :root => :string_terminal)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_string_terminal_case_insensitive
    match = File.parse('`a`', :root => :string_terminal)
    assert(match)
    assert_kind_of(Rule, match.value)
    assert_instance_of(StringTerminal, match.value)
  end

  def test_single_quoted_string
    match = File.parse("'test'", :root => :quoted_string)
    assert(match)
    assert_equal('test', match.value)
  end

  def test_single_quoted_string_embedded_single_quote
    match = File.parse("'te\\'st'", :root => :quoted_string)
    assert(match)
    assert_equal("te'st", match.value)
  end

  def test_single_quoted_string_embedded_double_quote
    match = File.parse("'te\"st'", :root => :quoted_string)
    assert(match)
    assert_equal('te"st', match.value)
  end

  def test_double_quoted_string
    match = File.parse('"test"', :root => :quoted_string)
    assert(match)
    assert_equal('test', match.value)
  end

  def test_double_quoted_string_embedded_double_quote
    match = File.parse('"te\\"st"', :root => :quoted_string)
    assert(match)
    assert_equal('te"st', match.value)
  end

  def test_double_quoted_string_embedded_single_quote
    match = File.parse('"te\'st"', :root => :quoted_string)
    assert(match)
    assert_equal("te'st", match.value)
  end

  def test_double_quoted_string_hex
    match = File.parse('"\\x26"', :root => :quoted_string)
    assert(match)
    assert_equal('&', match.value)
  end

  def test_case_insensitive_string
    match = File.parse('`test`', :root => :case_insensitive_string)
    assert(match)
    assert_equal('test', match.value)
  end

  def test_case_insensitive_string_embedded_double_quote
    match = File.parse('`te\\"st`', :root => :case_insensitive_string)
    assert(match)
    assert_equal('te"st', match.value)
  end

  def test_case_insensitive_string_embedded_backtick
    match = File.parse('`te\`st`', :root => :case_insensitive_string)
    assert(match)
    assert_equal("te`st", match.value)
  end

  def test_case_insensitive_string_hex
    match = File.parse('`\\x26`', :root => :case_insensitive_string)
    assert(match)
    assert_equal('&', match.value)
  end

  def test_character_class
    match = File.parse('[_]', :root => :character_class)
    assert(match)
    assert_equal(/\A[_]/, match.value)
  end

  def test_character_class_a_z
    match = File.parse('[a-z]', :root => :character_class)
    assert(match)
    assert_equal(/\A[a-z]/, match.value)
  end

  def test_character_class_a_z_0_9
    match = File.parse('[a-z0-9]', :root => :character_class)
    assert(match)
    assert_equal(/\A[a-z0-9]/, match.value)
  end

  def test_character_class_nested_square_brackets
    match = File.parse('[\[-\]]', :root => :character_class)
    assert(match)
    assert_equal(/\A[\[-\]]/, match.value)
  end

  def test_character_class_hex_range
    match = File.parse('[\\x26-\\x29]', :root => :character_class)
    assert(match)
    assert_equal(/\A[\x26-\x29]/, match.value)
  end

  def test_dot
    match = File.parse('.', :root => :dot)
    assert(match)
    assert_equal(DOT, match.value)
  end

  def test_regular_expression
    match = File.parse('/./', :root => :regular_expression)
    assert(match)
    assert_equal(/./, match.value)
  end

  def test_regular_expression_escaped_forward_slash
    match = File.parse('/\\//', :root => :regular_expression)
    assert(match)
    assert_equal(/\//, match.value)
  end

  def test_regular_expression_escaped_backslash
    match = File.parse('/\\\\/', :root => :regular_expression)
    assert(match)
    assert_equal(/\\/, match.value)
  end

  def test_regular_expression_hex
    match = File.parse('/\\x26/', :root => :regular_expression)
    assert(match)
    assert_equal(/\x26/, match.value)
  end

  def test_regular_expression_with_flag
    match = File.parse('/a/i', :root => :regular_expression)
    assert(match)
    assert_equal(/a/i, match.value)
  end

  def test_predicate_and
    match = File.parse('&', :root => :predicate)
    assert(match)
    assert_kind_of(Rule, match.value(''))
  end

  def test_predicate_not
    match = File.parse('!', :root => :predicate)
    assert(match)
    assert_kind_of(Rule, match.value(''))
  end

  def test_and
    match = File.parse('&', :root => :and)
    assert(match)
    assert_instance_of(AndPredicate, match.value(''))
  end

  def test_and_space
    match = File.parse('& ', :root => :and)
    assert(match)
    assert_instance_of(AndPredicate, match.value(''))
  end

  def test_not
    match = File.parse('!', :root => :not)
    assert(match)
    assert_instance_of(NotPredicate, match.value(''))
  end

  def test_not_space
    match = File.parse('! ', :root => :not)
    assert(match)
    assert_instance_of(NotPredicate, match.value(''))
  end

  def test_label
    match = File.parse('label:', :root => :label)
    assert(match)
    assert_equal(:label, match.value)
  end

  def test_label_spaced
    match = File.parse('a_label : ', :root => :label)
    assert(match)
    assert_equal(:a_label, match.value)
  end

  def test_tag
    match = File.parse('<Module>', :root => :tag)
    assert(match)
    assert_equal(Module, match.value)
  end

  def test_tag_inner_space
    match = File.parse('< Module >', :root => :tag)
    assert(match)
    assert_equal(Module, match.value)
  end

  def test_tag_space
    match = File.parse('<Module> ', :root => :tag)
    assert(match)
    assert_equal(Module, match.value)
  end

  def test_block
    match = File.parse('{}', :root => :block)
    assert(match)
    assert(match.value)
  end

  def test_block_space
    match = File.parse("{} \n", :root => :block)
    assert(match)
    assert(match.value)
  end

  def test_block_n
    match = File.parse('{ 2 }', :root => :block)
    assert(match)
    assert(match.value)
    assert_equal(2, match.value.call)
  end

  def test_block_with_hash
    match = File.parse("{ {:a => :b}\n}", :root => :block)
    assert(match)
    assert(match.value)
    assert_equal({:a => :b}, match.value.call)
  end

  def test_block_proc
    match = File.parse("{|b|\n  Proc.new(&b)\n}", :root => :block)
    assert(match)
    assert(match.value)

    b = match.value.call(Proc.new { :hi })

    assert(b)
    assert_equal(:hi, b.call)
  end

  def test_block_def
    match = File.parse("{\n  def value\n    'a'\n  end\n} ", :root => :block)
    assert(match)
    assert(match.value)
  end

  def test_block_with_interpolation
    match = File.parse('{ "#{number}" }', :root => :block)
    assert(match)
    assert(match.value)
  end

  def test_repeat_question
    match = File.parse('?', :root => :repeat)
    assert(match)
    assert_instance_of(Repeat, match.value(''))
  end

  def test_repeat_plus
    match = File.parse('+', :root => :repeat)
    assert(match)
    assert_instance_of(Repeat, match.value(''))
  end

  def test_repeat_star
    match = File.parse('*', :root => :repeat)
    assert(match)
    assert_instance_of(Repeat, match.value(''))
  end

  def test_repeat_n_star
    match = File.parse('1*', :root => :repeat)
    assert(match)
    assert_instance_of(Repeat, match.value(''))
  end

  def test_repeat_star_n
    match = File.parse('*2', :root => :repeat)
    assert(match)
    assert_instance_of(Repeat, match.value(''))
  end

  def test_repeat_n_star_n
    match = File.parse('1*2', :root => :repeat)
    assert(match)
    assert_instance_of(Repeat, match.value(''))
  end

  def test_question
    match = File.parse('?', :root => :question)
    assert(match)
    assert_equal(0, match.min)
    assert_equal(1, match.max)
  end

  def test_question_space
    match = File.parse('? ', :root => :question)
    assert(match)
    assert_equal(0, match.min)
    assert_equal(1, match.max)
  end

  def test_plus
    match = File.parse('+', :root => :plus)
    assert(match)
    assert_equal(1, match.min)
    assert_equal(Infinity, match.max)
  end

  def test_plus_space
    match = File.parse('+ ', :root => :plus)
    assert(match)
    assert_equal(1, match.min)
    assert_equal(Infinity, match.max)
  end

  def test_star
    match = File.parse('*', :root => :star)
    assert(match)
    assert_equal(0, match.min)
    assert_equal(Infinity, match.max)
  end

  def test_n_star
    match = File.parse('1*', :root => :star)
    assert(match)
    assert_equal(1, match.min)
    assert_equal(Infinity, match.max)
  end

  def test_star_n
    match = File.parse('*2', :root => :star)
    assert(match)
    assert_equal(0, match.min)
    assert_equal(2, match.max)
  end

  def test_n_star_n
    match = File.parse('1*2', :root => :star)
    assert(match)
    assert_equal(1, match.min)
    assert_equal(2, match.max)
  end

  def test_n_star_n_space
    match = File.parse('1*2 ', :root => :star)
    assert(match)
    assert_equal(1, match.min)
    assert_equal(2, match.max)
  end

  def test_module_name
    match = File.parse('Module', :root => :module_name)
    assert(match)
    assert_equal('Module', match)
  end

  def test_module_name_space
    match = File.parse('Module ', :root => :module_name)
    assert(match)
    assert_equal('Module', match.first)
  end

  def test_module_name_colon_colon
    match = File.parse('::Proc', :root => :module_name)
    assert(match)
    assert_equal('::Proc', match)
  end

  def test_constant
    match = File.parse('Math', :root => :constant)
    assert(match)
    assert_equal('Math', match)
  end

  def test_constant_invalid
    assert_raise ParseError do
      File.parse('math', :root => :constant)
    end
  end

  def test_comment
    match = File.parse('# A comment.', :root => :comment)
    assert(match)
    assert_equal('# A comment.', match)
  end
end
