require 'citrus'

module Citrus
  # A grammar for Citrus grammar files. This grammar is used in Citrus#eval to
  # parse and evaluate Citrus grammars and serves as a prime example of how to
  # create a complex grammar complete with semantic interpretation in pure Ruby.
  File = Grammar.new do

    ## Hierarchical syntax

    rule :file do
      all(:space, zero_or_more(any(:require, :grammar))) {
        def requires
          find(:require)
        end

        def grammars
          find(:grammar)
        end

        def value
          requires.each {|r| require r.value }
          grammars.map {|g| g.value }
        end
      }
    end

    rule :grammar do
      all(:grammar_keyword, :module_name, :grammar_body, :end_keyword) {
        def includes
          find(:include)
        end

        def modules
          includes.map {|inc| eval(inc.value, TOPLEVEL_BINDING) }
        end

        def root
          find(:root).last
        end

        def rules
          find(:rule)
        end

        def value
          code = '%s = Citrus::Grammar.new' % module_name.value
          grammar = eval(code, TOPLEVEL_BINDING)
          modules.each {|mod| grammar.include(mod) }
          grammar.root(root.value) if root
          rules.each {|rule| grammar.rule(rule.rule_name.value, rule.value) }
          grammar
        end
      }
    end

    rule :grammar_body do
      zero_or_more(any(:include, :root, :rule))
    end

    rule :rule do
      all(:rule_keyword, :rule_name, :rule_body, :end_keyword) {
        def value
          rule_body.value
        end
      }
    end

    rule :rule_body do
      all(:sequence, :choice) {
        def choices
          @choices ||= [ sequence ] + choice.sequences
        end

        def values
          choices.map {|c| c.value }
        end

        def value
          choices.length > 1 ? Choice.new(values) : values[0]
        end
      }
    end

    rule :choice do
      zero_or_more([ :bar, :sequence ]) {
        def sequences
          matches.map {|m| m.matches[1] }
        end
      }
    end

    rule :sequence do
      zero_or_more(:prefix) {
        def values
          matches.map {|m| m.value }
        end

        def value
          matches.length > 1 ? Sequence.new(values) : values[0]
        end
      }
    end

    rule :prefix do
      all(zero_or_one(:qualifier), :appendix) {
        def value
          rule = appendix.value
          qualifier = matches[0].first
          rule = qualifier.wrap(rule) if qualifier
          rule
        end
      }
    end

    rule :appendix do
      all(:suffix, zero_or_one(:extension)) {
        def value
          rule = suffix.value
          extension = matches[1].first
          extension.apply(rule) if extension
          rule
        end
      }
    end

    rule :suffix do
      all(:primary, zero_or_one(:quantifier)) {
        def value
          rule = primary.value
          quantifier = matches[1].first
          rule = quantifier.wrap(rule) if quantifier
          rule
        end
      }
    end

    rule :primary do
      any(:super, :alias, :rule_body_paren, :terminal)
    end

    rule :rule_body_paren do
      all(:lparen, :rule_body, :rparen) {
        def value
          rule_body.value
        end
      }
    end

    ## Lexical syntax

    rule :require do
      all(:require_keyword, :quoted_string) {
        def value
          quoted_string.value
        end
      }
    end

    rule :include do
      all(:include_keyword, :module_name) {
        def value
          module_name.value
        end
      }
    end

    rule :root do
      all(:root_keyword, :rule_name) {
        def value
          rule_name.value
        end
      }
    end

    rule :rule_name do
      all(/[a-zA-Z_-]+/, :space) {
        def value
          first.text
        end
      }
    end

    rule :super do
      all('super', :space) {
        def value
          Super.new
        end
      }
    end

    rule :alias do
      all(notp(:end_keyword), :rule_name) {
        def value
          Alias.new(rule_name.value)
        end
      }
    end

    rule :terminal do
      any(:quoted_string, :character_class, :anything_symbol, :regular_expression) {
        def value
          Rule.create(super)
        end
      }
    end

    rule :quoted_string do
      all(/(["'])(?:\\?.)*?\1/, :space) {
        def value
          eval(first.text)
        end
      }
    end

    rule :character_class do
      all(/\[(?:\\?.)*?\]/, :space) {
        def value
          Regexp.new('\A' + first.text)
        end
      }
    end

    rule :anything_symbol do
      all('.', :space) {
        def value
          /./m # Match newlines
        end
      }
    end

    rule :regular_expression do
      all(/\/(?:\\?.)*?\/[imxouesn]*/, :space) {
        def value
          eval(first.text)
        end
      }
    end

    rule :qualifier do
      any(:and, :not, :label)
    end

    rule :and do
      all('&', :space) {
        def wrap(rule)
          AndPredicate.new(rule)
        end
      }
    end

    rule :not do
      all('!', :space) {
        def wrap(rule)
          NotPredicate.new(rule)
        end
      }
    end

    rule :label do
      all(/[a-zA-Z0-9_]+/, :space, ':', :space) {
        def wrap(rule)
          Label.new(value, rule)
        end

        def value
          first.text
        end
      }
    end

    rule :extension do
      any(:tag, :block) {
        def apply(rule)
          rule.extension = value
        end
      }
    end

    rule :tag do
      all(:lt, :module_name, :gt) {
        def value
          eval(module_name.value, TOPLEVEL_BINDING)
        end
      }
    end

    rule :block do
      all(:lcurly, zero_or_more(any(:block, /[^{}]+/)), :rcurly) {
        def value
          eval('Proc.new ' + text)
        end
      }
    end

    rule :quantifier do
      any(:question, :plus, :repeat) {
        def wrap(rule)
          Repeat.new(min, max, rule)
        end
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

    rule :repeat do
      all(/[0-9]*/, '*', /[0-9]*/, :space) {
        def min
          matches[0] == '' ? 0 : matches[0].text.to_i
        end

        def max
          matches[2] == '' ? Infinity : matches[2].text.to_i
        end
      }
    end

    rule :module_name do
      all(one_or_more([ zero_or_one('::'), :constant ]), :space) {
        def value
          first.text
        end
      }
    end

    rule :constant do
      /[A-Z][a-zA-Z0-9_]*/
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

    rule :white,            /[ \t\n\r]/
    rule :comment,          /#.*/
    rule :space,            zero_or_more(any(:white, :comment))
  end
end
