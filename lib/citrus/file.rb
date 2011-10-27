# encoding: UTF-8

require 'citrus'

module Citrus
  # Some helper methods for rules that alias +module_name+ and don't want to
  # use +Kernel#eval+ to retrieve Module objects.
  module ModuleNameHelpers #:nodoc:
    def module_segments
      @module_segments ||= module_name.value.split('::')
    end

    def module_namespace
      module_segments[0...-1].inject(Object) do |namespace, constant|
        constant.empty? ? namespace : namespace.const_get(constant)
      end
    end

    def module_basename
      module_segments.last
    end
  end

  # A grammar for Citrus grammar files. This grammar is used in Citrus.eval to
  # parse and evaluate Citrus grammars and serves as a prime example of how to
  # create a complex grammar complete with semantic interpretation in pure Ruby.
  File = Grammar.new do #:nodoc:

    ## Hierarchical syntax

    rule :file do
      all(:space, zero_or_more(any(:require, :grammar))) {
        captures[:require].each do |req|
          file = req.value
          begin
            require file
          rescue ::LoadError => e
            begin
              Citrus.require(file)
            rescue LoadError
              # Re-raise the original LoadError.
              raise e
            end
          end
        end

        captures[:grammar].map {|g| g.value }
      }
    end

    rule :grammar do
      mod all(:grammar_keyword, :module_name, zero_or_more(any(:include, :root, :rule)), :end_keyword) do
        include ModuleNameHelpers

        def value
          grammar = module_namespace.const_set(module_basename, Grammar.new)

          captures[:include].each {|inc| grammar.include(inc.value) }
          captures[:rule].each {|r| grammar.rule(r.rule_name.value, r.value) }

          grammar.root(root.value) if root

          grammar
        end
      end
    end

    rule :rule do
      all(:rule_keyword, :rule_name, zero_or_one(:expression), :end_keyword) {
        # An empty rule definition matches the empty string.
        expression ? expression.value : Rule.for('')
      }
    end

    rule :expression do
      all(:sequence, zero_or_more([['|', zero_or_one(:space)], :sequence])) {
        rules = captures[:sequence].map {|s| s.value }
        rules.length > 1 ? Choice.new(rules) : rules.first
      }
    end

    rule :sequence do
      one_or_more(:labelled) {
        rules = captures[:labelled].map {|l| l.value }
        rules.length > 1 ? Sequence.new(rules) : rules.first
      }
    end

    rule :labelled do
      all(zero_or_one(:label), :extended) {
        rule = extended.value
        rule.label = label.value if label
        rule
      }
    end

    rule :extended do
      all(:prefix, zero_or_one(:extension)) {
        rule = prefix.value
        rule.extension = extension.value if extension
        rule
      }
    end

    rule :prefix do
      all(zero_or_one(:predicate), :suffix) {
        rule = suffix.value
        rule = predicate.value(rule) if predicate
        rule
      }
    end

    rule :suffix do
      all(:primary, zero_or_one(:repeat)) {
        rule = primary.value
        rule = repeat.value(rule) if repeat
        rule
      }
    end

    rule :primary do
      any(:grouping, :proxy, :terminal)
    end

    rule :grouping do
      all(['(', zero_or_one(:space)], :expression, [')', zero_or_one(:space)]) {
        expression.value
      }
    end

    ## Lexical syntax

    rule :require do
      all(:require_keyword, :quoted_string) {
        quoted_string.value
      }
    end

    rule :include do
      mod all(:include_keyword, :module_name) do
        include ModuleNameHelpers

        def value
          module_namespace.const_get(module_basename)
        end
      end
    end

    rule :root do
      all(:root_keyword, :rule_name) {
        rule_name.value
      }
    end

    # Rule names may contain letters, numbers, underscores, and dashes. They
    # MUST start with a letter.
    rule :rule_name do
      all(/[a-zA-Z][a-zA-Z0-9_-]*/, :space) {
        first.to_s
      }
    end

    rule :proxy do
      any(:super, :alias)
    end

    rule :super do
      all('super', andp(" "), :space) {
        Super.new
      }
    end

    rule :alias do
      all(notp(:end_keyword), :rule_name) {
        Alias.new(rule_name.value)
      }
    end

    rule :terminal do
      any(:quoted_string, :case_insensitive_string, :regular_expression, :character_class, :dot) {
        primitive = super()

        if String === primitive
          StringTerminal.new(primitive, flags)
        else
          Terminal.new(primitive)
        end
      }
    end

    rule :quoted_string do
      mod all(/(["'])(?:\\?.)*?\1/, :space) do
        def value
          eval(first.to_s)
        end

        def flags
          0
        end
      end
    end

    rule :case_insensitive_string do
      mod all(/`(?:\\?.)*?`/, :space) do
        def value
          eval(first.to_s.gsub(/^`|`$/, '"'))
        end

        def flags
          Regexp::IGNORECASE
        end
      end
    end

    rule :regular_expression do
      all(/\/(?:\\?.)*?\/[imxouesn]*/, :space) {
        eval(first.to_s)
      }
    end

    rule :character_class do
      all(/\[(?:\\?.)*?\]/, :space) {
        eval("/#{first.to_s.gsub('/', '\\/')}/")
      }
    end

    rule :dot do
      all('.', :space) {
        DOT
      }
    end

    rule :label do
      all(/[a-zA-Z0-9_]+/, :space, ':', :space) {
        first.to_sym
      }
    end

    rule :extension do
      any(:tag, :block)
    end

    rule :tag do
      mod all(
        ['<', zero_or_one(:space)],
        :module_name,
        ['>', zero_or_one(:space)]
      ) do
        include ModuleNameHelpers

        def value
          module_namespace.const_get(module_basename)
        end
      end
    end

    rule :block do
      all(
        '{',
        zero_or_more(any(:block, /[^{}]+/)),
        ['}', zero_or_one(:space)]
      ) {
        proc = eval("Proc.new #{to_s}", TOPLEVEL_BINDING)

        # Attempt to detect if this is a module block using some
        # extremely simple heuristics.
        if to_s =~ /\b(def|include) /
          Module.new(&proc)
        else
          proc
        end
      }
    end

    rule :predicate do
      any(:and, :not, :but)
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

    rule :repeat do
      any(:question, :plus, :star)
    end

    rule :question do
      all('?', :space) { |rule|
        Repeat.new(rule, 0, 1)
      }
    end

    rule :plus do
      all('+', :space) { |rule|
        Repeat.new(rule, 1, Infinity)
      }
    end

    rule :star do
      all(/[0-9]*/, '*', /[0-9]*/, :space) { |rule|
        min = captures[1] == '' ? 0 : captures[1].to_i
        max = captures[3] == '' ? Infinity : captures[3].to_i
        Repeat.new(rule, min, max)
      }
    end

    rule :module_name do
      all(one_or_more([ zero_or_one('::'), :constant ]), :space) {
        first.to_s
      }
    end

    rule :require_keyword,  [ /\brequire\b/, :space ]
    rule :include_keyword,  [ /\binclude\b/, :space ]
    rule :grammar_keyword,  [ /\bgrammar\b/, :space ]
    rule :root_keyword,     [ /\broot\b/, :space ]
    rule :rule_keyword,     [ /\brule\b/, :space ]
    rule :end_keyword,      [ /\bend\b/, :space ]

    rule :constant,         /[A-Z][a-zA-Z0-9_]*/
    rule :white,            /[ \t\n\r]/
    rule :comment,          /#.*/
    rule :space,            zero_or_more(any(:white, :comment))
  end

  def File.parse(*) # :nodoc:
    super
  rescue ParseError => e
    # Raise SyntaxError when a parse fails.
    raise SyntaxError, e
  end
end
