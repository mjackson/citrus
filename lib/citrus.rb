require 'forwardable'

module Citrus
  VERSION = [0, 1, 0]

  def self.version
    VERSION.join('.')
  end

  Infinity = 1.0 / 0

  module Grammar
    # Creates a new Grammar as an anonymous module. If a block is provided, it
    # will be called with the new Grammar as its first argument if its +arity+
    # is 1 or +instance_eval+'d in the context of the new Grammar otherwise.
    #
    # See http://blog.grayproductions.net/articles/dsl_block_styles
    def self.new(&block)
      mod = Module.new { include Grammar }
      (block.arity == 1 ? block[self] : mod.instance_eval(&block)) if block
      mod
    end

    def self.included(base)
      class << base
        include GrammarMethods
        include GrammarDSL
      end
    end
  end

  module Invoke
    def instance
      mod = self
      @instance ||= (Class.new { include mod }).new
    end

    def invoke(sym, *args)
      instance.__send__(sym, *args)
    end
  end

  module GrammarMethods
    # Returns the name of this grammar as a String.
    def name
      super.to_s
    end

    # Returns all names of rules of this grammar as Symbols in an Array.
    # Rules are ordered in the same way they were defined in the grammar.
    def rule_names
      instance_methods
    end

    # Returns +true+ if this grammar contains a rule with the given +name+.
    def has_rule?(name)
      rule_names.include?(name.to_sym)
    end

    # Returns a map of the names of all rules in this grammar to their
    # respective Rule objects. Useful when debugging grammars.
    def rules
      rule_names.inject({}) {|m, sym| m[sym] = rule(sym); m }
    end

    # Parses the given +string+ from the given +offset+. If +consume_all+ is
    # true, will return +nil+ unless the entire string can be consumed.
    def parse(string, offset=0, consume_all=true)
      raise "No root rule specified" unless root
      raise "No rule named \"#{root}\"" unless has_rule?(root)

      input = Input.new(string)

      m = input.match(rule(root), offset)
      m unless consume_all && m && m.length != string.length
    end
  end

  module GrammarDSL
    include Invoke

    # Gets/sets the Rule object with the given +name+. If a block is given,
    # will use the return value of the block as the primitive value to pass to
    # Rule#create. All rules are stored as instance methods of the grammar
    # module so that grammars may be composed naturally as Ruby modules.
    def rule(name, &block)
      sym = name.to_sym

      # The first rule in a grammar is the default root.
      @root ||= sym

      # Keep track of the name of the rule currently being defined so we can
      # use it if #sup is called without an explicit name.
      @current_name = sym

      if block
        rule = Rule.create(block.call)
        rule.name = name
        rule.grammar = self
        define_method(sym) { rule }
      end

      invoke(sym) if has_rule?(name)
    end

    # Gets/sets the name of the root rule of this grammar.
    def root(name=nil)
      @root = name.to_sym if name
      @root
    end

    # Works like Ruby's +super+, but for rules. When defining a grammar, this
    # will return the Rule object from the most recently included grammar with
    # a rule of the same +name+. If +name+ is not supplied it defaults to the
    # name of the rule currently being defined.
    def sup(name=@current_name)
      grammars = included_modules.select {|mod| mod.include?(Grammar) }
      grammars.each do |grammar|
        return grammar.rule(name) if grammar.has_rule?(name)
      end
      raise ArgumentError, "Cannot use super. No rule named \"#{name}\" " +
       "found in inheritance hierarchy"
    end

    def and(obj)
      AndPredicate.new(obj)
    end

    def not(obj)
      NotPredicate.new(obj)
    end

    def rep(obj, min=1, max=Infinity)
      Repeat.new(obj, min, max)
    end

    def one_or_more(obj)
      rep(obj)
    end

    def zero_or_more(obj)
      rep(obj, 0)
    end

    def zero_or_one(obj)
      rep(obj, 0, 1)
    end

    def all(*args)
      Sequence.new(args)
    end

    def any(*args)
      Choice.new(args)
    end
  end

  # The core of the packrat parsing algorithm, this class wraps a string that
  # is to be parsed and keeps track of matches for all rules at any given
  # offset.
  #
  # See http://en.wikipedia.org/wiki/Parsing_expression_grammar
  class Input
    extend Forwardable

    attr_reader :string, :cache, :cache_hits

    def_delegators :@string, :[], :length

    def initialize(string)
      @string = string
      @cache = {}
      @cache_hits = 0
    end

    # Returns the match for a given +rule+ at a given +offset+.
    def match(rule, offset=0)
      c = @cache[rule.id] ||= {}

      if c.key?(offset)
        @cache_hits += 1
        c[offset]
      else
        c[offset] = rule.match(self, offset)
      end
    end
  end

  # A Rule is an object that is used by the parser to match on the input.
  class Rule
    # Automatically creates a rule depending on the type of object given.
    def self.create(obj)
      case obj
      when Rule     then obj
      when Symbol   then Proxy.new(obj)
      when String   then FixedWidth.new(obj)
      when Regexp   then Expression.new(obj)
      when Array    then Sequence.new(obj)
      when Range    then Choice.new(obj.to_a)
      when Numeric  then FixedWidth.new(obj.to_s)
      else
        raise ArgumentError, "Unable to create rule for #{obj.inspect}"
      end
    end

    attr_reader :name, :grammar
    attr_writer :grammar

    def name=(name)
      @name = name.to_sym
    end

    # Returns +true+ if this rule is a Terminal.
    def terminal?
      is_a? Terminal
    end

    # Returns +true+ if this rule has a name.
    def named?
      !! @name
    end

    # Returns +true+ if this rule needs to be surrounded by parentheses when
    # being augmented.
    def paren?
      false
    end

    def id
      named? ? name.to_s : (terminal? ? to_s : object_id.to_s)
    end

    # Returns a string version of this rule that is suitable to be used as part
    # of some other rule.
    def embed
      named? ? name.to_s : (paren? ? '(%s)' % to_s : to_s)
    end

    def inspect
      to_s
    end

  private

    def create_match(match)
      Match.new(match)
    end
  end

  # A Proxy is a Rule that is a facade for another rule. It is used in grammar
  # definitions when a rule uses some other rule by name. The PEG notation is
  # simply the name of a rule without any other punctuation, e.g.:
  #
  #     expr
  #
  class Proxy < Rule
    def initialize(name)
      self.name = name
    end

    def rule
      unless @rule
        rule = grammar.rule(name)
        raise RuntimeError, "No rule named \"#{name}\" in grammar " +
          grammar.name unless rule
        @rule = rule
      end
      @rule
    end

    def method_missing(sym, *args)
      rule.__send__(sym, *args)
    end

    def to_s
      name.to_s
    end
  end

  # A Terminal is a Rule that matches directly on the input stream and may not
  # contain any other rule.
  class Terminal < Rule
    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    def to_s
      rule.inspect
    end
  end

  # A FixedWidth is a Terminal that matches based on its length. The PEG
  # notation is any sequence of characters enclosed in either single or double
  # quotes, e.g.:
  #
  #     'expr'
  #     "expr"
  #
  class FixedWidth < Terminal
    def initialize(rule='')
      raise ArgumentError, "FixedWidth must be a String" unless String === rule
      super
    end

    def match(input, offset=0)
      result = rule == input[offset, rule.length]
      create_match(rule.dup) if result
    end
  end

  # An Expression is a Terminal that has the same semantics as a regular
  # expression in Ruby. The expression must match at the beginning of the input
  # (index 0). The PEG notation is identical to Ruby's regular expression
  # notation, e.g.:
  #
  #     /expr/
  #
  class Expression < Terminal
    def initialize(rule=/^$/)
      raise ArgumentError, "Expression must be a Regexp" unless Regexp === rule
      super
    end

    def match(input, offset=0)
      result = input[offset, input.length - offset].match(rule)
      create_match(result) if result && result.begin(0) == 0
    end
  end

  # A Nonterminal is a Rule that augments the matching behavior of one or more
  # other rules. Nonterminals may not match directly on the input, but instead
  # invoke the rule(s) they contain to determine if a match can be made from
  # the collective result.
  class Nonterminal < Rule
    attr_reader :rules

    def initialize(rules=[])
      @rules = rules.map {|r| Rule.create(r) }
    end

    def grammar=(grammar)
      @rules.each {|r| r.grammar = grammar }
      super
    end
  end

  # A Predicate is a Nonterminal that contains one other rule.
  class Predicate < Nonterminal
    def initialize(rule='')
      super([ rule ])
    end

    def rule
      rules[0]
    end
  end

  # An AndPredicate is a Predicate that contains a rule that must match.
  # However, no input is consumed. The PEG notation is any expression
  # preceeded by an ampersand, e.g.:
  #
  #     &expr
  #
  class AndPredicate < Predicate
    def match(input, offset=0)
      create_match('') if input.match(rule, offset)
    end

    def to_s
      '&' + rule.embed
    end
  end

  # A NotPredicate is a Predicate that contains a rule that must not match.
  # No input is consumed. The PEG notation is any expression preceeded by an
  # exclamation point, e.g.:
  #
  #     !expr
  #
  class NotPredicate < Predicate
    def match(input, offset=0)
      create_match('') unless input.match(rule, offset)
    end

    def to_s
      '!' + rule.embed
    end
  end

  # A Repeat is a Predicate that specifies a minimum and maximum number of times
  # its rule must match. The PEG notation is an integer, +<n>+, followed by an
  # asterisk, followed by another integer, +<m>+, all of which follow any other
  # expression, e.g.:
  #
  #     expr<n>*<m>
  #
  # In this notation +<n>+ specifies the minimum number of times the preceeding
  # expression must match and +<m>+ specifies the maximum. If +<n>+ is ommitted,
  # it is assumed to be 0. Likewise, if +<m>+ is omitted, it is assumed to be
  # infinity (no maximum). Thus, an expression followed by only an asterisk may
  # match any number of times, including zero.
  #
  # The shorthand notation <tt>+</tt> and <tt>?</tt> may be used for the common
  # cases of <tt>1*</tt> and <tt>*1</tt> respectively, e.g.:
  #
  #     expr+
  #     expr?
  #
  class Repeat < Predicate
    def initialize(rule='', min=1, max=Infinity)
      super(rule)
      raise ArgumentError, "Min cannot be greater than max" if min > max
      @range = Range.new(min, max)
    end

    def match(input, offset=0)
      matches = []
      while matches.length < @range.end
        m = input.match(rule, offset)
        break unless m
        matches << m
        offset += m.length
      end
      create_match(matches) if @range.include?(matches.length)
    end

    def operator
      m = [@range.begin, @range.end].map do |n|
        n == 0 || n == Infinity ? '' : n.to_s
      end
      case m
      when ['', '1'] then '?'
      when ['1', ''] then '+'
      else m.join('*')
      end
    end

    def to_s
      rule.embed + operator
    end
  end

  # A List is a Nonterminal that contains any number of other rules and tests
  # them for matches in sequential order.
  class List < Nonterminal
    def paren?
      rules.length > 1
    end
  end

  # A Choice is a List where only one rule must match. The PEG notation is two
  # or more expressions separated by a forward slash, e.g.:
  #
  #     expr / expr
  #
  class Choice < List
    def match(input, offset=0)
      rules.each do |rule|
        m = input.match(rule, offset)
        return m if m
      end
      nil
    end

    def to_s
      rules.map {|r| r.embed }.join(' / ')
    end
  end

  # A Sequence is a List where all rules must match. The PEG notation is two or
  # more expressions separated by a space, e.g.:
  #
  #     expr expr
  #
  class Sequence < List
    def match(input, offset=0)
      matches = []
      rules.each do |rule|
        m = input.match(rule, offset)
        break unless m
        matches << m
        offset += m.length
      end
      create_match(matches) if matches.length == rules.length
    end

    def to_s
      rules.map {|r| r.embed }.join(' ')
    end
  end

  class Match
    attr_reader :result, :captures

    def initialize(result, ext=nil)
      case result
      when String, Array
        @result = result
        @captures = []
      when MatchData
        @result = result[0]
        @captures = result.captures
      else
        raise ArgumentError, "Invalid match result: #{result.inspect}"
      end

      extend(ext) if Module === ext
    end

    def value
      @value ||= Array === @result ?
        @result.inject('') {|m, v| m << v.value } : @result
    end

    def length
      @length ||= Array === @result ?
        @result.inject(0) {|m, v| m + v.length } : value.length
    end

    alias :to_s :value
  end
end
