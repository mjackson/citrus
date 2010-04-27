require 'forwardable'

module Citrus

  VERSION = [0, 1, 0]

  def self.version
    VERSION.join('.')
  end

  Infinity = 1.0 / 0

  class Grammar
    class << self
      attr_reader :rules

      def inherited(sub)
        sub.instance_variable_set(:@rules, {})
      end

      def method_missing(sym, *args)
        rules.key?(sym) ? rules[sym] : sym
      end

      # Parses the given +string+ according to the rules of this grammar.
      def parse(string, offset=0, consume_all=true)
        raise "No root rule specified" if root.nil?
        raise "No rule named \"#{root}\"" unless rules.key?(root)

        input = Input.new(string, offset)
        input.grammar = self

        m = input.match(rules[root])
        return nil if consume_all && !input.done?
        m
      end

      ## DSL Methods

      # Copies all rules from the given +grammar+ into this grammar,
      # overwriting any existing rule that may have the same name.
      def copy(grammar)
        grammar.rules.each_pair {|name, obj| rule(name, obj) }
      end

      # Sets the name of the root rule of this grammar. Returns the name of the
      # root rule.
      def root(name=nil)
        @root = name.to_sym if name.respond_to?(:to_sym)
        @root
      end

      def rule(name, rule=nil)
        raise "Invalid name \"#{name.inspect}\"" unless name.respond_to?(:to_sym)
        sym = name.to_sym
        if rule
          r = Rule.create(rule)
          r.name = sym
          @rules[sym] = r
          # The first rule in a grammar is the default root.
          @root ||= sym
        end
        @rules[sym]
      end

      def and_predicate(rule)
        AndPredicate.new(rule)
      end
      alias and and_predicate

      def not_predicate(rule)
        NotPredicate.new(rule)
      end
      alias not not_predicate

      def repeat(rule, min=1, max=Infinity)
        Repeat.new(rule, min, max)
      end

      def one_or_more(rule)
        repeat(rule)
      end

      def zero_or_more(rule)
        repeat(rule, 0)
      end

      def zero_or_one(rule)
        repeat(rule, 0, 1)
      end

      def sequence(*rules)
        Sequence.new(rules)
      end
      alias all sequence

      def choice(*rules)
        Choice.new(rules)
      end
      alias any choice
    end
  end

  class Input
    extend Forwardable

    attr_accessor :offset
    attr_reader :string, :cache, :cache_hits
    attr_writer :grammar

    def_delegators :@string, :[], :length

    def initialize(string, offset=0)
      @string, @offset = string, offset
      @cache = {}
      @cache_hits = 0
    end

    def match(rule)
      # TODO: Figure out a cleaner way to resolve Proxy rules to the Rule
      # objects they represent. Input objects should probably be able to
      # operate independent of the grammar.
      if Proxy === rule
        rule = @grammar.rule(rule.name)
        raise "No rule named \"#{name}\"" unless Rule === rule
      end

      @cache[rule.id] ||= {}

      if @cache[rule.id].key?(offset)
        @cache_hits += 1
        @cache[rule.id][offset]
      else
        @cache[rule.id][offset] = rule.match(self)
      end
    end

    def consume(match)
      @offset += match.length
      match
    end

    def done?
      offset == length
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

    attr_reader :name

    def name=(name)
      @name = name.to_sym
    end

    def id
      named? ? name.to_s : (terminal? ? to_s : object_id.to_s)
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
    def match(input)
      result = rule == input[input.offset, rule.length]
      input.consume(create_match(rule.dup)) if result
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
    def match(input)
      result = input[input.offset, input.length - input.offset].match(rule)
      input.consume(create_match(result)) if result && result.begin(0) == 0
    end
  end

  class Nonterminal < Rule
    attr_reader :rules

    def initialize(rules)
      @rules = rules.map {|r| Rule.create(r) }
    end
  end

  # A Predicate is a non-terminal Rule that augments the matching behavior of
  # one other rule.
  class Predicate < Nonterminal
    def initialize(rule)
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
    def match(input)
      offset = input.offset
      m = input.match(rule)
      input.offset = offset
      create_match('') if m
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
    def match(input)
      offset = input.offset
      m = input.match(rule)
      input.offset = offset
      create_match('') unless m
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
    def initialize(rule, min=1, max=Infinity)
      super(rule)
      raise ArgumentError, "Min cannot be greater than max" if min > max
      @range = Range.new(min, max)
    end

    def match(input)
      offset = input.offset
      matches = []
      while matches.length < @range.end
        m = input.match(rule)
        break unless m
        matches << m
      end
      return create_match(matches) if @range.include?(matches.length)
      input.offset = offset
      nil
    end

    def operator
      m = [@range.begin, @range.end].map do |n|
        n == 0 || n == Infinity ? '' : n.to_s
      end
      if m[0] == '' && m[1] == '1'
        '?'
      elsif m[0] == '1' && m[1] == ''
        '+'
      else
        m.join('*')
      end
    end

    def to_s
      rule.embed + operator
    end
  end

  # A List is a non-terminal Rule that contains any number of other rules and
  # augments their collective matching behavior. Rules that are part of a List
  # are always tested for matches in sequential order.
  class List < Nonterminal
    def paren?
      rules.length > 1
    end
  end

  # A Sequence is a List where all rules must match. The PEG notation is two or
  # more expressions separated by a space, e.g.:
  #
  #     expr expr
  #
  class Sequence < List
    def match(input)
      offset = input.offset
      matches = []
      rules.each do |r|
        m = input.match(r)
        break unless m
        matches << m
      end
      return create_match(matches) if matches.length == rules.length
      input.offset = offset
      nil
    end

    def to_s
      rules.map {|r| r.embed }.join(' ')
    end
  end

  # A Choice is a List where only one rule must match. The PEG notation is two
  # or more expressions separated by a forward slash, e.g.:
  #
  #     expr / expr
  #
  class Choice < List
    def match(input)
      offset = input.offset
      rules.each do |r|
        m = input.match(r)
        return m if m
        input.offset = offset
      end
      nil
    end

    def to_s
      rules.map {|r| r.embed }.join(' / ')
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
