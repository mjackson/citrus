module Citrus
  # A Rule is an object that is used by a grammar to create matches on the
  # Input during parsing.
  class Rule
    # Evaluates the given expression and creates a new rule object from it.
    #
    #     Citrus::Rule.eval('"a" | "b"')
    #
    def self.eval(expr)
      Citrus.parse(expr, :root => :rule_body, :consume => true).value
    end

    # Returns a new Rule object depending on the type of object given.
    def self.for(obj)
      case obj
      when Rule     then obj
      when Symbol   then Alias.new(obj)
      when String   then StringTerminal.new(obj)
      when Regexp   then Terminal.new(obj)
      when Array    then Sequence.new(obj)
      when Range    then Choice.new(obj.to_a)
      when Numeric  then StringTerminal.new(obj.to_s)
      else
        raise ArgumentError, "Invalid rule object: %s" % obj.inspect
      end
    end

    def ==(other)
      case other
      when Rule
        kind_of?(other.class) and @string == other.to_s
      else
        super
      end
    end

    # The grammar this rule belongs to.
    attr_accessor :grammar

    # Sets the name of this rule.
    def name=(name)
      @name = name.to_sym
    end

    # The name of this rule.
    attr_reader :name

    # Specifies a module that will be used to extend all Match objects that
    # result from this rule. If +mod+ is a Proc, it is used to create an
    # anonymous module.
    def extension=(mod)
      if Proc === mod
        mod = Module.new { define_method(:value, &mod) }
      end

      raise ArgumentError unless Module === mod

      @extension = mod
    end

    # The module this rule uses to extend new matches.
    attr_reader :extension

    # Attempts to parse the given +string+ and return a Match if any can be
    # made. The +options+ may contain any of the following keys:
    #
    # offset::    The offset in +string+ at which to start the parse. Defaults
    #             to 0.
    # memoize::   If this is +true+ the matches generated during a parse are
    #             memoized. See Input#memoize! for more information. Defaults to
    #             +false+.
    # consume::   If this is +true+ a ParseError will be raised during a parse
    #             unless the entire input string is consumed. Defaults to
    #             +false+.
    def parse(string, options={})
      opts = default_parse_options.merge(options)

      if opts[:memoize]
        input = MemoizingInput.new(string)
      else
        input = Input.new(string)
      end

      input.pos = opts[:offset] if opts[:offset] > 0

      events = input.exec(self)
      length = events[-1]

      if !length || (opts[:consume] && length < (input.length - opts[:offset]))
        raise ParseError.new(input)
      end

      Match.new(string.slice(opts[:offset], length), events)
    end

    # The default set of options to use when parsing.
    def default_parse_options # :nodoc:
      { :offset   => 0,
        :memoize  => false,
        :consume  => false
      }
    end

    # Tests whether or not this rule matches on the given +string+. Returns the
    # length of the match if any can be made, +nil+ otherwise.
    def test(string)
      input = Input.new(string)
      input.test(self)
    end

    # Returns +true+ if this rule is a Terminal.
    def terminal?
      is_a?(Terminal)
    end

    # Returns +true+ if this rule is able to propagate extensions from child
    # rules to the scope of the parent when extending matches. In general, this
    # returns +false+ for any rule that uses an arbitrary number of child rules
    # when determining whether or not it can match, such as a Repeat or a
    # Sequence. This is not true for Choice objects because they rely on exactly
    # one rule to match, as do Proxy objects.
    def propagates_extensions?
      case self
      when AndPredicate, NotPredicate, ButPredicate, Repeat, Sequence
        false
      else
        true
      end
    end

    # Returns +true+ if this rule needs to be surrounded by parentheses when
    # using #embed.
    def needs_paren?
      is_a?(Nonterminal) && rules.length > 1
    end

    # Returns a string version of this rule that is suitable to be used in the
    # string representation of another rule.
    def embed
      name ? name.to_s : (needs_paren? ? "(#{to_s})" : to_s)
    end

    def inspect # :nodoc:
      to_s
    end

    def extend_match(match) # :nodoc:
      match.names << name if name
      match.extend(extension) if extension
    end

    class Application
      def initialize(rule, len, comp=nil)
        @rule = rule
        @length = len
        @compositions = comp
      end

      # The rule being applied
      attr_reader :rule

      # The length of the text matched by this application
      attr_reader :length

      # The applications this application is composed of
      attr_reader :compositions

      def show(indent="")
        puts "#{indent}#{@rule} -- #{@length}"
        @compositions.each do |n|
          n.show "  #{indent}"
        end
      end

      # For the event stream, reconstruct highlevel info about the rules
      # and operands
      def self.from_events(events)
        rule = events.shift
        unless rule
          raise "invalid stream"
        end

        sub = []
        until events[0] == CLOSE
          sub << from_events(events)
        end

        events.shift # close

        Application.new(rule, events.shift, sub)
      end
    end
  end
end
