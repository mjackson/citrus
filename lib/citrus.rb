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
        sym
      end

      def compile!
        @rules.each_pair {|key, rule| @rules[key] = rule.compile!(self) }
        @compiled = true
      end

      def compiled?
        !! @compiled
      end

      def valid_name?(name)
        name.respond_to?(:to_sym)
      end

      def parse(input)
        raise "No start rule specified" if @root.nil?
        raise "No rule named \"#{@root}\"" unless @rules.key?(@root)

        compile! unless compiled?

        rule = @rules[@root]
        rule.match(input, 0)
      end

      ## DSL Methods

      # Sets the name of the root rule of this grammar. Will always return
      # the name of the root rule, even when given no arguments.
      def root(name=nil)
        @root = name.to_sym if valid_name?(name)
        @root
      end

      def rule(name)
        raise "Invalid rule name \"#{name.inspect}\"" unless valid_name?(name)
        sym = name.to_sym
        if block_given?
          rule = Rule.create(instance_eval(&Proc.new))
          rule.name = name
          @rules[sym] = rule
          @compiled = false
        end
        @rules[sym]
      end

      def ignore
      end

      def sequence(*rules)
        Sequence.new(rules)
      end
      alias :all :sequence

      def choice(*rules)
        Choice.new(rules)
      end
      alias :any :choice

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

  class Rule
    # Automatically creates a rule depending on the type of object given.
    def self.create(obj)
      case obj
      when Rule           then obj
      when String, Regexp then Terminal.create(obj)
      when Numeric        then Terminal.create(obj.to_s)
      when Array          then Sequence.new(obj)
      when Range          then Choice.new(obj.to_a)
      when Symbol
        # Symbols are names of other rules and are resolved at compile time,
        # not when they are created.
        Proxy.new(obj)
      else
        raise ArgumentError, "Unable to create rule for #{obj.inspect}"
      end
    end

    attr_reader :name

    # Returns a string id that is unique to this Rule.
    def id
      object_id.to_s
    end

    def name=(name)
      @name = name.to_sym
    end

    # Returns +true+ if this rule is a Terminal.
    def terminal?
      is_a? Terminal
    end

    def compile!(grammar)
      self
    end

    # Returns +true+ if the string representation of this Rule should be
    # enclosed in parentheses when it is augmented by some other rule.
    def paren?
      false
    end
  end

  # A Terminal is a Rule that is able to match directly on the input at a given
  # offset. Thus, all subclasses of Terminal must contain a method named
  # `match` that takes two arguments, 1) the `input` string and 2) the current
  # offset in the input, and returns a Match if one is able to be made.
  class Terminal < Rule
    @cache = {}

    class << self
      attr_reader :cache

      # No reason to create duplicate terminal objects. They all function
      # the same.
      def create(obj)
        @cache[obj] ||= Regexp === obj ? Expression.new(obj) : FixedWidth.new(obj)
      end
    end

    def initialize(rule)
      @rule = rule
    end

    def to_s
      @rule.inspect
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
    def match(input, offset=0)
      Match.new(@rule.dup) if input[offset, @rule.length] == @rule
    end
  end

  # An Expression is a terminal Rule that has the same semantics as a regular
  # expression in Ruby. It matches by calling Regexp#match on the remainder of
  # the input from the current offset.
  #
  # It is important to note when using Expression terminals that if the given
  # regular expression does not match at the beginning of the input string
  # (i.e. does not start with a `^` character) that Ruby's regular expression
  # engine will skip any number of characters until it can find a match. This
  # behavior may not be desirable when writing a PEG because the goal is to
  # fully describe any token that may be encountered in the input. However, it
  # is left up to the user to decide whether or not to take advantage of this
  # behavior.
  #
  # The PEG notation is identical to Ruby's regular expression notation, e.g.:
  #
  #   /expr/
  #
  class Expression < Terminal
    def match(input, offset=0)
      result = input[offset, input.length - offset].match(@rule)
      Match.new(result) if result
    end
  end

  # A Sequence is a non-terminal Rule that serves as a container for any number
  # of rules, all of which must match. The rules are iterated over in sequence,
  # providing a predictable traversal. The PEG notation is a list of expressions
  # separated by a space, e.g.:
  #
  #   expr expr
  #
  class Sequence < Rule
    def initialize(rules=[])
      @rules = rules.map {|r| Rule.create(r) }
    end

    def match(input, offset=0)
      pos, matches = 0, []
      @rules.each do |rule|
        m = rule.match(input, offset + pos)
        break unless m
        matches << m
        pos += (m.length + m.offset)
      end
      Match.new(matches) if matches.length == @rules.length
    end

    def compile!(grammar)
      @rules.map! {|r| r.compile!(grammar) }
      self
    end

    def paren?
      @rules.length > 1
    end

    def to_s
      @rules.map {|r|
        s = r.to_s
        s = '(' + s + ')' if r.paren?
        s
      }.join(' ')
    end
  end

  # A Choice is a Sequence where only one Rule must match. The PEG notation is
  # a list of expressions separated by a backslash character, e.g.:
  #
  #   expr / expr
  #
  class Choice < Rule
    def initialize(rules=[])
      @rules = rules.map {|r| Rule.create(r) }
    end

    def match(input, offset=0)
      @rules.each do |rule|
        m = rule.match(input, offset)
        return m if m
      end
      nil
    end

    def compile!(grammar)
      @rules.map! {|r| r.compile!(grammar) }
      self
    end

    def paren?
      @rules.length > 1
    end

    def to_s
      @rules.map {|r|
        s = r.to_s
        s = '(' + s + ')' if r.paren?
        s
      }.join(' / ')
    end
  end

  # A Repeat is a non-terminal Rule that specifies a minimum and maximum number
  # of times that another Rule must match in order to succeed. The PEG notation
  # is an integer, <n>, followed by an asterisk, followed by another integer,
  # <m>, all of which follow any other expression, e.g.:
  #
  #   expr<n>*<m>
  #
  # In this notation <n> specifies the minimum number of times the preceeding
  # expression must match and <m> specifies the maximum. If <n> is ommitted, it
  # is assumed to be 0. Likewise, if <m> is omitted, it is assumed to be
  # infinity (no maximum). Thus, an expression followed by only an asterisk may
  # match any number of times, including zero.
  #
  # The shorthand notation `+` and `?` may be used for the common cases of `1*`
  # and `*1` respectively, e.g.:
  #
  #   expr+
  #   expr?
  #
  class Repeat < Rule
    def initialize(rule, min=1, max=1)
      raise ArgumentError, "Min cannot be greater than max" if min > max
      @rule, @min, @max = Rule.create(rule), min, max
    end

    def match(input, offset=0)
      pos, matches = 0, []
      while matches.length < @max
        m = @rule.match(input, offset + pos)
        break unless m
        matches << m
        pos += (m.length + m.offset)
      end
      Match.new(matches) if matches.length >= @min && matches.length <= @max
    end

    def compile!(grammar)
      @rule = @rule.compile!(grammar)
      self
    end

    def to_s
      m = [@min, @max].map {|n| n == 0 || n == Infinity ? '' : n.to_s }
      if m[0] == '' && m[1] == '1'
        m = '?'
      elsif m[0] == '1' && m[1] == ''
        m = '+'
      else
        m = m.join('*')
      end
      s = @rule.to_s
      s = '(' + s + ')' if @rule.paren?
      s + m
    end
  end

  class Proxy < Rule
    def initialize(name)
      self.name = name
    end

    def compile!(grammar)
      rule = grammar.rule(@name)
      raise "No rule named \"#{@name}\"" unless Rule === rule
      rule
    end
  end

  class Match
    attr_reader :result, :offset, :captures

    def initialize(result, ext=nil)
      case result
      when String, Array
        @result = result
        @offset = 0
        @captures = []
      when MatchData
        @result = result[0]
        @offset = result.begin(0)
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
