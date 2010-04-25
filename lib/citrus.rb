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

      def compile!
        @ignore = @ignore.compile!(self) if @ignore
        @rules.each_pair {|key, rule| @rules[key] = rule.compile!(self) }
        @compiled = true
      end

      def compiled?
        !! @compiled
      end

      def valid_name?(name)
        name.respond_to?(:to_sym)
      end

      def parse(string)
        raise "No root rule specified" if root.nil?
        raise "No rule named \"#{root}\"" unless rules.key?(root)

        compile! unless compiled?

        input = Input.new(string, ignore)

        # Skip any leading ignored tokens before attempting to match.
        input.skip

        root_rule = rules[root]
        matches = []
        last_offset = -1
        until input.done?
          # If no progress has been made since last time then we may assume
          # that we cannot consume any more of this input.
          return nil if last_offset == input.offset
          last_offset = input.offset
          matches << root_rule.match(input)
        end
        matches
      end

      ## DSL Methods

      # Defines a rule that may match between any two Terminal tokens in the
      # input and will be ignored. Will always return the ignore rule.
      def ignore(rule=nil)
        @ignore = Rule.create(rule) if rule
        @ignore
      end

      # Sets the name of the root rule of this grammar. Will always return
      # the name of the root rule.
      def root(name=nil)
        @root = name.to_sym if valid_name?(name)
        @root
      end

      def rule(name, *args)
        raise "Invalid rule name \"#{name.inspect}\"" unless valid_name?(name)
        sym = name.to_sym
        unless args.empty?
          rule = Rule.create(args.length == 1 ? args.first : args)
          rule.name = name
          @rules[sym] = rule
          @compiled = false
        end
        @rules[sym]
      end

      def sequence(*rules)
        Sequence.new(rules)
      end
      alias :all :sequence

      def choice(*rules)
        Choice.new(rules)
      end
      alias :any :choice

      def and_predicate(rule)
        AndPredicate.new(rule)
      end
      alias :and :and_predicate

      def not_predicate(rule)
        NotPredicate.new(rule)
      end
      alias :not :not_predicate

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
    end
  end

  class Input
    extend Forwardable

    attr_accessor :offset

    def initialize(string, ignore=nil)
      @offset = 0
      @string, @ignore = string, ignore
    end

    def_delegators :@string, :[], :length

    def rest
      self[offset, length - offset]
    end

    def skip
      @ignore.match(self) if @ignore
    end

    def consume(match)
      @offset += match.length
      skip
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
      when Numeric  then FixedWidth.new(obj.to_s)
      when Array    then Sequence.new(obj)
      when Range    then Choice.new(obj.to_a)
      else
        raise ArgumentError, "Unable to create rule for #{obj.inspect}"
      end
    end

    attr_reader :name

    def name=(name)
      @name = name.to_sym
    end

    # By default a Rule will return itself when compiled. The only exceptions
    # are Proxy objects.
    def compile!(grammar)
      self
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
  end

  # A Proxy is a Rule that resolves to another Rule when compiled. It is used
  # in grammar definitions when a rule uses some other rule that has not yet
  # been defined. In these cases, a Proxy is returned which merely wraps the
  # name of the yet-to-be-defined rule in an object and returns the real Rule
  # object at compile time. The PEG notation is simply the name of a rule
  # without any other punctuation, e.g.:
  #
  #   expr
  #
  class Proxy < Rule
    def initialize(name)
      self.name = name
    end

    def compile!(grammar)
      rule = grammar.rule(name)
      raise "No rule named \"#{name}\"" unless Rule === rule
      rule
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

  # A FixedWidth is a terminal Rule that matches based on its length. The PEG
  # notation is any sequence of characters enclosed in either single or double
  # quotes, e.g.:
  #
  #   'expr'
  #   "expr"
  #
  class FixedWidth < Terminal
    def match(input)
      if rule == input[input.offset, rule.length]
        m = Match.new(rule.dup)
        input.consume(m)
        m
      end
    end
  end

  # An Expression is a terminal Rule that has the same semantics as a regular
  # expression in Ruby. It matches by calling Regexp#match on the input stream
  # at the current offset. If the regular expression matches at the beginning
  # of the stream (i.e. index 0) the rule succeeds. The PEG notation is
  # identical to Ruby's regular expression notation, e.g.:
  #
  #   /expr/
  #
  # In order to maintain compatibility with some other PEG implementations,
  # character classes may be denoted by one or more characters or character
  # ranges enclosed in square brackets, e.g.:
  #
  #   [a-zA-Z_]
  #
  class Expression < Terminal
    def match(input)
      result = input.rest.match(rule)
      if result && result.begin(0) == 0
        m = Match.new(result)
        input.consume(m)
        m
      end
    end
  end

  # A Predicate is a non-terminal Rule that augments the matching behavior of
  # one other rule.
  class Predicate < Rule
    attr_reader :rule

    def initialize(rule)
      @rule = Rule.create(rule)
    end

    def compile!(grammar)
      @rule = @rule.compile!(grammar)
      self
    end
  end

  # An AndPredicate is a Predicate that contains a rule that must match.
  # However, no input is consumed. The PEG notation is any expression
  # preceeded by an ampersand, e.g.:
  #
  #   &expr
  #
  class AndPredicate < Predicate
    def match(input)
      offset = input.offset
      m = rule.match(input)
      input.offset = offset
      Match.new('') if m
    end

    def to_s
      '&' + rule.embed
    end
  end

  # A NotPredicate is a Predicate that contains a rule that must not match.
  # No input is consumed. The PEG notation is any expression preceeded by an
  # exclamation point, e.g.:
  #
  #   !expr
  #
  class NotPredicate < Predicate
    def match(input)
      offset = input.offset
      m = rule.match(input)
      input.offset = offset
      Match.new('') unless m
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
  #   expr<n>*<m>
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
  #   expr+
  #   expr?
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
        m = rule.match(input)
        break unless m
        matches << m
      end
      return Match.new(matches) if @range.include?(matches.length)
      input.offset = offset
      nil
    end

    def to_s
      m = [@range.begin, @range.end].map do |n|
        n == 0 || n == Infinity ? '' : n.to_s
      end
      if m[0] == '' && m[1] == '1'
        m = '?'
      elsif m[0] == '1' && m[1] == ''
        m = '+'
      else
        m = m.join('*')
      end
      rule.embed + m
    end
  end

  # A List is a non-terminal Rule that contains any number of other rules and
  # augments their matching behavior in some way.
  class List < Rule
    attr_reader :rules

    def initialize(rules)
      @rules = rules.map {|r| Rule.create(r) }
    end

    def compile!(grammar)
      @rules.map! {|r| r.compile!(grammar) }
      self
    end

    def paren?
      rules.length > 1
    end
  end

  # A Sequence is a List where all rules must match in sequential order. The
  # PEG notation is a list of expressions separated by a space, e.g.:
  #
  #   expr expr
  #
  class Sequence < List
    def match(input)
      offset = input.offset
      matches = []
      rules.each do |r|
        m = r.match(input)
        break unless m
        matches << m
      end
      return Match.new(matches) if matches.length == rules.length
      input.offset = offset
      nil
    end

    def to_s
      rules.map {|r| r.embed }.join(' ')
    end
  end

  # A Choice is a List where only one rule must match. Rules that are part of a
  # Choice are tested in sequential order. The PEG notation is a list of
  # expressions separated by a forward slash, e.g.:
  #
  #   expr / expr
  #
  class Choice < List
    def match(input)
      offset = input.offset
      rules.each do |r|
        m = r.match(input)
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
