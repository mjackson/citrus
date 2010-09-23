require 'citrus'

module Citrus
  # A grammar for Citrus grammar files. This grammar is used in Citrus#eval to
  # parse and evaluate Citrus grammars and serves as a prime example of how to
  # create a complex grammar complete with semantic interpretation in pure Ruby.
  File = Grammar.new do

    ## Hierarchical syntax

    rule :file do
      all(:space, zero_or_more(any(:require, :grammar))) {
        find(:require).each { |r| require r.value }
        find(:grammar).map { |g| g.value }
      }
    end

    rule :grammar do
      all(:grammar_keyword, :module_name, :grammar_body, :end_keyword) {
        code = '%s = Citrus::Grammar.new' % module_name.value
        grammar = eval(code, TOPLEVEL_BINDING)

        modules = find(:include).map { |inc| eval(inc.value, TOPLEVEL_BINDING) }
        modules.each { |mod| grammar.include(mod) }

        root = find(:root).last
        grammar.root(root.value) if root

        find(:rule).each { |r| grammar.rule(r.rule_name.value, r.value) }

        grammar
      }
    end

    rule :grammar_body do
      zero_or_more(any(:include, :root, :rule))
    end

    rule :rule do
      all(:rule_keyword, :rule_name, :rule_body, :end_keyword) {
        rule_body.value
      }
    end

    rule :rule_body do
      all(:sequence, :choice) {
        @choices ||= [ sequence ] + choice.value
        values = @choices.map { |c| c.value }
        values.length > 1 ? Choice.new(values) : values[0]
      }
    end

    rule :choice do
      zero_or_more([ :bar, :sequence ]) {
        matches.map { |m| m.matches[1] }
      }
    end

    rule :sequence do
      zero_or_more(:appendix) {
        values = matches.map { |m| m.value }
        values.length > 1 ? Sequence.new(values) : values[0]
      }
    end

    rule :appendix do
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
      any(:grouping, :proxy, :terminal)
    end

    rule :grouping do
      all(:lparen, :rule_body, :rparen) { rule_body.value }
    end

    ## Lexical syntax

    rule :require do
      all(:require_keyword, :quoted_string) { quoted_string.value }
    end

    rule :include do
      all(:include_keyword, :module_name) { module_name.value }
    end

    rule :root do
      all(:root_keyword, :rule_name) { rule_name.value }
    end

    # Rule names may contain letters, numbers, underscores, and dashes. They
    # MUST start with a letter.
    rule :rule_name do
      all(/[a-zA-Z][a-zA-Z0-9_-]*/, :space) { first.text }
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

    rule :terminal do
      any(:quoted_string, :character_class, :dot, :regular_expression) {
        Rule.new(super())
      }
    end

    rule :quoted_string do
      all(/(["'])(?:\\?.)*?\1/, :space) {
        eval(first.text)
      }
    end

    rule :character_class do
      all(/\[(?:\\?.)*?\]/, :space) {
        Regexp.new('\A' + first.text, nil, 'n')
      }
    end

    rule :dot do
      all('.', :space) {
        DOT
      }
    end

    rule :regular_expression do
      all(/\/(?:\\?.)*?\/[imxouesn]*/, :space) {
        eval(first.text)
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
        Label.new(rule, first.text)
      }
    end

    rule :extension do
      any(:tag, :block)
    end

    rule :tag do
      all(:lt, :module_name, :gt) {
        eval(module_name.value, TOPLEVEL_BINDING)
      }
    end

    rule :block do
      all(:lcurly, zero_or_more(any(:block, /[^}]+/)), :rcurly) {
        eval('Proc.new ' + text)
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
        def min; matches[0] == '' ? 0 : matches[0].text.to_i end
        def max; matches[2] == '' ? Infinity : matches[2].text.to_i end
      }
    end

    rule :module_name do
      all(one_or_more([ zero_or_one('::'), :constant ]), :space) {
        first.text
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
