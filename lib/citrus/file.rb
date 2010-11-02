require 'citrus'

module Citrus
  # Some helper methods for rules that alias +module_name+ and don't want to
  # use +Kernel#eval+ to retrieve Module objects.
  module ModuleHelpers #:nodoc:
    def module_segments
      @module_segments ||= module_name.value.split('::')
    end

    def module_namespace
      module_segments[0..-2].inject(Object) do |namespace, constant|
        constant.empty? ? namespace : namespace.const_get(constant)
      end
    end

    def module_basename
      module_segments.last
    end
  end

  # A grammar for Citrus grammar files. This grammar is used in Citrus#eval to
  # parse and evaluate Citrus grammars and serves as a prime example of how to
  # create a complex grammar complete with semantic interpretation in pure Ruby.
  File = Grammar.new do #:nodoc:

    ## Hierarchical syntax

    rule :file do
      all(:space, zero_or_more(any(:require, :grammar))) {
        find(:require).each {|r| require r.value }
        find(:grammar).map {|g| g.value }
      }
    end

    rule :grammar do
      all(:grammar_keyword, :module_name, :grammar_body, :end_keyword) {
        include ModuleHelpers

        def value
          module_namespace.const_set(module_basename, grammar_body.value)
        end
      }
    end

    rule :grammar_body do
      zero_or_more(any(:include, :root, :rule)) {
        grammar = Grammar.new

        find(:include).map do |inc|
          grammar.include(inc.value)
        end

        root = find(:root).last
        grammar.root(root.value) if root

        find(:rule).each do |r|
          grammar.rule(r.rule_name.value, r.value)
        end

        grammar
      }
    end

    rule :rule do
      all(:rule_keyword, :rule_name, :rule_body, :end_keyword) {
        rule_body.value
      }
    end

    rule :rule_body do
      zero_or_one(:choice) {
        # An empty rule definition matches the empty string.
        matches.length > 0 ? choice.value : Rule.new('')
      }
    end

    rule :choice do
      all(:sequence, zero_or_more([ :bar, :sequence ])) {
        def rules
          @rules ||= [ sequence.value ] + matches[1].matches.map {|m| m.matches[1].value }
        end

        def value
          rules.length > 1 ? Choice.new(rules) : rules.first
        end
      }
    end

    rule :sequence do
      one_or_more(:expression) {
        def rules
          @rules ||= matches.map {|m| m.value }
        end

        def value
          rules.length > 1 ? Sequence.new(rules) : rules.first
        end
      }
    end

    rule :expression do
      all(:prefix, zero_or_one(:extension)) {
        rule = prefix.value
        extension = matches[1].first
        rule.extension = extension.value if extension
        rule
      }
    end

    rule :prefix do
      all(zero_or_one(:predicate), :suffix) {
        rule = suffix.value
        predicate = matches[0].first
        rule = predicate.value(rule) if predicate
        rule
      }
    end

    rule :suffix do
      all(:primary, zero_or_one(:repeat)) {
        rule = primary.value
        repeat = matches[1].first
        rule = repeat.value(rule) if repeat
        rule
      }
    end

    rule :primary do
      any(:grouping, :proxy, :string_terminal, :terminal)
    end

    rule :grouping do
      all(:lparen, :rule_body, :rparen) { rule_body.value }
    end

    ## Lexical syntax

    rule :require do
      all(:require_keyword, :quoted_string) { quoted_string.value }
    end

    rule :include do
      all(:include_keyword, :module_name) {
        include ModuleHelpers

        def value
          module_namespace.const_get(module_basename)
        end
      }
    end

    rule :root do
      all(:root_keyword, :rule_name) { rule_name.value }
    end

    # Rule names may contain letters, numbers, underscores, and dashes. They
    # MUST start with a letter.
    rule :rule_name do
      all(/[a-zA-Z][a-zA-Z0-9_-]*/, :space) { first.to_s }
    end

    rule :proxy do
      any(:super, :alias)
    end

    rule :super do
      all('super', :space) {
        Super.new
      }
    end

    rule :alias do
      all(notp(:end_keyword), :rule_name) {
        Alias.new(rule_name.value)
      }
    end

    rule :string_terminal do
      any(:quoted_string, :case_insensitive_string) {
        StringTerminal.new(super(), flags)
      }
    end

    rule :quoted_string do
      all(/(["'])(?:\\?.)*?\1/, :space) {
        def value
          eval(first)
        end

        def flags
          0
        end
      }
    end

    rule :case_insensitive_string do
      all(/`(?:\\?.)*?`/, :space) {
        def value
          eval(first.gsub(/^`|`$/, '"'))
        end

        def flags
          Regexp::IGNORECASE
        end
      }
    end

    rule :terminal do
      any(:regular_expression, :character_class, :dot) {
        Terminal.new(super())
      }
    end

    rule :regular_expression do
      all(/\/(?:\\?.)*?\/[imxouesn]*/, :space) {
        eval(first)
      }
    end

    rule :character_class do
      all(/\[(?:\\?.)*?\]/, :space) {
        Regexp.new('\A' + first, nil, 'n')
      }
    end

    rule :dot do
      all('.', :space) {
        DOT
      }
    end

    rule :predicate do
      any(:and, :not, :but, :label)
    end

    rule :and do
      all('&', :space) { |rule|
        AndPredicate.new(rule)
      }
    end

    rule :not do
      all('!', :space) { |rule|
        NotPredicate.new(rule)
      }
    end

    rule :but do
      all('~', :space) { |rule|
        ButPredicate.new(rule)
      }
    end

    rule :label do
      all(/[a-zA-Z0-9_]+/, :space, ':', :space) { |rule|
        Label.new(rule, first.to_s)
      }
    end

    rule :extension do
      any(:tag, :block)
    end

    rule :tag do
      all(:lt, :module_name, :gt) {
        include ModuleHelpers

        def value
          module_namespace.const_get(module_basename)
        end
      }
    end

    rule :block do
      all(:lcurly, zero_or_more(any(:block, /[^{}]+/)), :rcurly) {
        eval('Proc.new ' + to_s)
      }
    end

    rule :repeat do
      any(:question, :plus, :star) { |rule|
        Repeat.new(rule, min, max)
      }
    end

    rule :question do
      all('?', :space) {
        def min; 0 end
        def max; 1 end
      }
    end

    rule :plus do
      all('+', :space) {
        def min; 1 end
        def max; Infinity end
      }
    end

    rule :star do
      all(/[0-9]*/, '*', /[0-9]*/, :space) {
        def min; matches[0] == '' ? 0 : matches[0].to_i end
        def max; matches[2] == '' ? Infinity : matches[2].to_i end
      }
    end

    rule :module_name do
      all(one_or_more([ zero_or_one('::'), :constant ]), :space) {
        first.to_s
      }
    end

    rule :require_keyword,  [ 'require', :space ]
    rule :include_keyword,  [ 'include', :space ]
    rule :grammar_keyword,  [ 'grammar', :space ]
    rule :root_keyword,     [ 'root', :space ]
    rule :rule_keyword,     [ 'rule', :space ]
    rule :end_keyword,      [ 'end', :space ]
    rule :lparen,           [ '(', :space ]
    rule :rparen,           [ ')', :space ]
    rule :lcurly,           [ '{', :space ]
    rule :rcurly,           [ '}', :space ]
    rule :bar,              [ '|', :space ]
    rule :lt,               [ '<', :space ]
    rule :gt,               [ '>', :space ]

    rule :constant,         /[A-Z][a-zA-Z0-9_]*/
    rule :white,            /[ \t\n\r]/
    rule :comment,          /#.*/
    rule :space,            zero_or_more(any(:white, :comment))
  end
end
