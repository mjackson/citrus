require 'strscan'

# Citrus is a compact and powerful parsing library for Ruby that combines the
# elegance and expressiveness of the language with the simplicity and power of
# parsing expressions.
#
# http://mjijackson.com/citrus
module Citrus
  autoload :File, 'citrus/file'

  VERSION = [2, 0, 1]

  # Returns the current version of Citrus as a string.
  def self.version
    VERSION.join('.')
  end

  # A pattern to match any character, including \\n.
  DOT = /./m

  Infinity = 1.0 / 0

  F = ::File

  # Loads the grammar from the given +file+ into the global scope using #eval.
  def self.load(file)
    file << '.citrus' unless F.file?(file)
    raise "Cannot find file #{file}" unless F.file?(file)
    raise "Cannot read file #{file}" unless F.readable?(file)
    self.eval(F.read(file))
  end

  # Evaluates the given Citrus parsing expression grammar +code+ in the global
  # scope. The +code+ may contain the definition of any number of modules.
  # Returns an array of any grammar modules that are created.
  def self.eval(code)
    File.parse(code).value
  end

  # This error is raised whenever a parse fails.
  class ParseError < Exception
    def initialize(input)
      @input = input
      msg = "Failed to parse input at offset %d\n" % offset
      msg << detail
      super(msg)
    end

    # The Input object that was used for the parse.
    attr_reader :input

    # Returns the 0-based offset at which the error occurred in the input, i.e.
    # the maximum offset in the input that was successfully parsed before the
    # error occurred.
    def offset
      input.max_offset
    end

    # Returns the text of the line on which the error occurred.
    def line
      lines[line_index]
    end

    # Returns the 1-based number of the line in the input where the error
    # occurred.
    def line_number
      line_index + 1
    end

    alias lineno line_number

    # Returns the 0-based offset at which the error occurred on the line on
    # which it occurred.
    def line_offset
      pos = 0
      each_line do |line|
        len = line.length
        return (offset - pos) if pos + len >= offset
        pos += len
      end
      0
    end

    # Returns a string that, when printed, gives a visual representation of
    # exactly where the error occurred on its line in the input.
    def detail
      "%s\n%s^" % [line, ' ' * line_offset]
    end

  private

    def string
      input.string
    end

    def lines
      string.send(string.respond_to?(:lines) ? :lines : :to_s).to_a
    end

    def each_line(&block)
      string.each_line(&block)
    end

    # Returns the 0-based number of the line in the input where the error
    # occurred.
    def line_index
      pos = 0
      idx = 0
      each_line do |line|
        pos += line.length
        return idx if pos >= offset
        idx += 1
      end
      0
    end
  end

  # Inclusion of this module into another extends the receiver with the grammar
  # helper methods in GrammarMethods. Although this module does not actually
  # provide any methods, constants, or variables to modules that include it, the
  # mere act of inclusion provides a useful lookup mechanism to determine if a
  # module is in fact a grammar.
  module Grammar
    # Creates a new anonymous module that includes Grammar. If a +block+ is
    # provided, it is +module_eval+'d in the context of the new module. Grammars
    # created with this method may be assigned a name by being assigned to some
    # constant, e.g.:
    #
    #     Calc = Citrus::Grammar.new {}
    #
    def self.new(&block)
      mod = Module.new { include Grammar }
      mod.module_eval(&block) if block
      mod
    end

    # Extends all modules that +include Grammar+ with GrammarMethods and
    # exposes Module#include.
    def self.included(mod)
      mod.extend(GrammarMethods)
      # Expose #include so it can be called publicly.
      class << mod; public :include end
    end
  end

  # Contains methods that are available to Grammar modules at the class level.
  module GrammarMethods
    def self.extend_object(obj)
      raise ArgumentError, "Grammars must be Modules" unless Module === obj
      super
    end

    # Returns the name of this grammar as a string.
    def name
      super.to_s
    end

    # Returns an array of all grammars that have been included in this grammar
    # in the reverse order they were included.
    def included_grammars
      included_modules.select {|mod| mod.include?(Grammar) }
    end

    # Returns an array of all names of rules in this grammar as symbols ordered
    # in the same way they were defined (i.e. rules that were defined later
    # appear later in the array).
    def rule_names
      @rule_names ||= []
    end

    # Returns a hash of all Rule objects in this grammar, keyed by rule name.
    def rules
      @rules ||= {}
    end

    # Returns +true+ if this grammar has a rule with the given +name+.
    def has_rule?(name)
      rules.key?(name.to_sym)
    end

    # Loops through the rule tree for the given +rule+ looking for any Super
    # rules. When it finds one, it sets that rule's rule name to the given
    # +name+.
    def setup_super(rule, name) # :nodoc:
      if Nonterminal === rule
        rule.rules.each {|r| setup_super(r, name) }
      elsif Super === rule
        rule.rule_name = name
      end
    end
    private :setup_super

    # Searches the inheritance hierarchy of this grammar for a rule named +name+
    # and returns it on success. Returns +nil+ on failure.
    def super_rule(name)
      sym = name.to_sym
      included_grammars.each do |g|
        r = g.rule(sym)
        return r if r
      end
      nil
    end

    # Gets/sets the rule with the given +name+. If +obj+ is given the rule
    # will be set to the value of +obj+ passed through Rule#new. If a block is
    # given, its return value will be used for the value of +obj+.
    #
    # It is important to note that this method will also check any included
    # grammars for a rule with the given +name+ if one cannot be found in this
    # grammar.
    def rule(name, obj=nil, &block)
      sym = name.to_sym
      obj = block.call if block

      if obj
        rule_names << sym unless has_rule?(sym)

        rule = Rule.new(obj)
        rule.name = name
        setup_super(rule, name)
        rule.grammar = self

        rules[sym] = rule
      end

      rules[sym] || super_rule(sym)
    rescue => e
      raise 'Cannot create rule "%s": %s' % [name, e.message]
    end

    # Gets/sets the +name+ of the root rule of this grammar. If no root rule is
    # explicitly specified, the name of this grammar's first rule is returned.
    def root(name=nil)
      @root = name.to_sym if name
      # The first rule in a grammar is the default root.
      @root || rule_names.first
    end

    # Creates a new rule that will match any single character. A block may be
    # provided to specify semantic behavior (via #ext).
    def dot(&block)
      ext(Rule.new(DOT), block)
    end

    # Creates a new Super for the rule currently being defined in the grammar. A
    # block may be provided to specify semantic behavior (via #ext).
    def sup(&block)
      ext(Super.new, block)
    end

    # Creates a new AndPredicate using the given +rule+. A block may be provided
    # to specify semantic behavior (via #ext).
    def andp(rule, &block)
      ext(AndPredicate.new(rule), block)
    end

    # Creates a new NotPredicate using the given +rule+. A block may be provided
    # to specify semantic behavior (via #ext).
    def notp(rule, &block)
      ext(NotPredicate.new(rule), block)
    end

    # Creates a new ButPredicate using the given +rule+. A block may be provided
    # to specify semantic behavior (via #ext).
    def but(rule, &block)
      ext(ButPredicate.new(rule), block)
    end

    alias butp but # For consistency with #andp and #notp.

    # Creates a new Label using the given +rule+ and +label+. A block may be
    # provided to specify semantic behavior (via #ext).
    def label(rule, label, &block)
      ext(Label.new(rule, label), block)
    end

    # Creates a new Repeat using the given +rule+. +min+ and +max+ specify the
    # minimum and maximum number of times the rule must match. A block may be
    # provided to specify semantic behavior (via #ext).
    def rep(rule, min=1, max=Infinity, &block)
      ext(Repeat.new(rule, min, max), block)
    end

    # An alias for #rep.
    def one_or_more(rule, &block)
      rep(rule, &block)
    end

    # An alias for #rep with a minimum of 0.
    def zero_or_more(rule, &block)
      rep(rule, 0, &block)
    end

    # An alias for #rep with a minimum of 0 and a maximum of 1.
    def zero_or_one(rule, &block)
      rep(rule, 0, 1, &block)
    end

    # Creates a new Sequence using all arguments. A block may be provided to
    # specify semantic behavior (via #ext).
    def all(*args, &block)
      ext(Sequence.new(args), block)
    end

    # Creates a new Choice using all arguments. A block may be provided to
    # specify semantic behavior (via #ext).
    def any(*args, &block)
      ext(Choice.new(args), block)
    end

    # Specifies a Module that will be used to extend all matches created with
    # the given +rule+. A block may also be given that will be used to create
    # an anonymous module. See Rule#ext=.
    def ext(rule, mod=nil, &block)
      rule = Rule.new(rule)
      mod = block if block
      rule.extension = mod if mod
      rule
    end

    # Parses the given input +string+ using the given +options+. If no match can
    # be made, a ParseError is raised. See #default_parse_options for a detailed
    # description of available parse options.
    def parse(string, options={})
      opts = default_parse_options.merge(options)
      raise 'No root rule specified' unless opts[:root]

      root_rule = rule(opts[:root])
      raise 'No rule named "%s"' % root unless root_rule

      input = Input.new(string)
      input.memoize! if opts[:memoize]
      input.pos = opts[:offset] if opts[:offset] > 0

      match = input.match(root_rule)
      if match.nil? || (opts[:consume] && input.length != match.length)
        raise ParseError.new(input)
      end

      match
    end

    # The default set of options that is used in #parse. The options hash may
    # have any of the following keys:
    #
    # offset::    The offset at which the parse should start. Defaults to 0.
    # root::      The name of the root rule to use for the parse. Defaults
    #             to the name supplied by calling #root.
    # memoize::   If this is +true+ the matches generated during a parse are
    #             memoized. See Input#memoize! for more information. Defaults to
    #             +false+.
    # consume::   If this is +true+ a ParseError will be raised during a parse
    #             unless the entire input string is consumed. Defaults to
    #             +false+.
    def default_parse_options
      { :offset   => 0,
        :root     => root,
        :memoize  => false,
        :consume  => false
      }
    end
  end

  # This class represents the core of the parsing algorithm. It wraps the input
  # string and serves matches to all nonterminals.
  class Input < StringScanner
    def initialize(string)
      super(string)
      @max_offset = 0
    end

    # The maximum offset that has been achieved during a parse.
    attr_reader :max_offset

    # A nested hash of rule id's to offsets and their respective matches. Only
    # present if memoing is enabled.
    attr_reader :cache

    # The number of times the cache was hit. Only present if memoing is enabled.
    attr_reader :cache_hits

    # Returns the length of this input.
    def length
      string.length
    end

    # Returns the match for a given +rule+ at the current position in the input.
    def match(rule)
      offset = pos
      match = rule.match(self)

      if match
        @max_offset = pos if pos > @max_offset
      else
        # Reset the position for the next attempt at a match.
        self.pos = offset
      end

      match
    end

    # Returns true if this input uses memoization to cache match results. See
    # #memoize!.
    def memoized?
      !! @cache
    end

    # Modifies this object to cache match results during a parse. This technique
    # (also known as "Packrat" parsing) guarantees parsers will operate in
    # linear time but costs significantly more in terms of time and memory
    # required to perform a parse. For more information, please read the paper
    # on Packrat parsing at http://pdos.csail.mit.edu/~baford/packrat/icfp02/.
    def memoize!
      return if memoized?

      # Using +instance_eval+ here preserves access to +super+ within the
      # methods we define inside the block.
      instance_eval do
        def match(rule)
          c = @cache[rule.id] ||= {}

          if c.key?(pos)
            @cache_hits += 1
            c[pos]
          else
            c[pos] = super
          end
        end

        def reset
          super
          @max_offset = 0
          @cache = {}
          @cache_hits = 0
        end
      end

      @cache = {}
      @cache_hits = 0
    end
  end

  # A Rule is an object that is used by a grammar to create matches on the
  # Input during parsing.
  module Rule
    # Evaluates the given expression and creates a new rule object from it.
    #
    #     Citrus::Rule.eval('"a" | "b"')
    #
    def self.eval(expr)
      File.parse(expr, :root => :rule_body).value
    end

    # Returns a new Rule object depending on the type of object given.
    def self.new(obj)
      case obj
      when Rule           then obj
      when Symbol         then Alias.new(obj)
      when String, Regexp then Terminal.new(obj)
      when Array          then Sequence.new(obj)
      when Range          then Choice.new(obj.to_a)
      when Numeric        then Terminal.new(obj.to_s)
      else
        raise ArgumentError, "Invalid rule object: %s" % obj.inspect
      end
    end

    @unique_id = 0

    # Generates a new rule id.
    def self.new_id
      @unique_id += 1
    end

    # The grammar this rule belongs to.
    attr_accessor :grammar

    # An integer id that is unique to this rule.
    def id
      @id ||= Rule.new_id
    end

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
        begin
          tmp = Module.new(&mod)
          raise ArgumentError unless tmp.instance_methods.any?
          mod = tmp
        rescue ArgumentError, NameError, NoMethodError
          mod = Module.new { define_method(:value, &mod) }
        end
      end

      raise ArgumentError unless Module === mod

      @extension = mod
    end

    # The module this rule uses to extend new matches.
    attr_reader :extension

    # Returns +true+ if this rule is a Terminal.
    def terminal?
      is_a?(Terminal)
    end

    # Returns +true+ if this rule needs to be surrounded by parentheses when
    # using #embed.
    def paren?
      false
    end

    # Returns a string version of this rule that is suitable to be used in the
    # string representation of another rule.
    def embed
      name ? name.to_s : (paren? ? '(%s)' % to_s : to_s)
    end

    def inspect # :nodoc:
      to_s
    end

  private

    def extend_match(match, name)
      match.extend(extension) if extension
      match.names << name if name
      match
    end

    def create_match(data)
      extend_match(Match.new(data), name)
    end
  end

  # A Proxy is a Rule that is a placeholder for another rule. It stores the
  # name of some other rule in the grammar internally and resolves it to the
  # actual Rule object at runtime. This lazy evaluation permits us to create
  # Proxy objects for rules that we may not know the definition of yet.
  module Proxy
    include Rule

    def initialize(rule_name='<proxy>')
      self.rule_name = rule_name
    end

    # Sets the name of the rule this rule is proxy for.
    def rule_name=(rule_name)
      @rule_name = rule_name.to_sym
    end

    # The name of this proxy's rule.
    attr_reader :rule_name

    # Returns the underlying Rule for this proxy.
    def rule
      @rule ||= resolve!
    end

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      m = input.match(rule)
      extend_match(m, name) if m
    end
  end

  # An Alias is a Proxy for a rule in the same grammar. It is used in rule
  # definitions when a rule calls some other rule by name. The Citrus notation
  # is simply the name of another rule without any other punctuation, e.g.:
  #
  #     name
  #
  class Alias
    include Proxy

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rule_name.to_s
    end

  private

    # Searches this proxy's grammar and any included grammars for a rule with
    # this proxy's #rule_name. Raises an error if one cannot be found.
    def resolve!
      rule = grammar.rule(rule_name)
      raise RuntimeError, 'No rule named "%s" in grammar %s' %
        [rule_name, grammar.name] unless rule
      rule
    end
  end

  # A Super is a Proxy for a rule of the same name that was defined previously
  # in the grammar's inheritance chain. Thus, Super's work like Ruby's +super+,
  # only for rules in a grammar instead of methods in a module. The Citrus
  # notation is the word +super+ without any other punctuation, e.g.:
  #
  #     super
  #
  class Super
    include Proxy

    # Returns the Citrus notation of this rule as a string.
    def to_s
      'super'
    end

  private

    # Searches this proxy's included grammars for a rule with this proxy's
    # #rule_name. Raises an error if one cannot be found.
    def resolve!
      rule = grammar.super_rule(rule_name)
      raise RuntimeError, 'No rule named "%s" in hierarchy of grammar %s' %
        [rule_name, grammar.name] unless rule
      rule
    end
  end

  # A Terminal is a Rule that matches directly on the input stream and may not
  # contain any other rule. Terminals may be created from either a String or a
  # Regexp object. When created from strings, the Citrus notation is any
  # sequence of characters enclosed in either single or double quotes, e.g.:
  #
  #     'expr'
  #     "expr"
  #
  # When created from a regular expression, the Citrus notation is identical to
  # Ruby's regular expression notation, e.g.:
  #
  #     /expr/
  #
  # Character classes and the dot symbol may also be used in Citrus notation for
  # compatibility with other parsing expression implementations, e.g.:
  #
  #     [a-zA-Z]
  #     .
  #
  class Terminal
    include Rule

    def initialize(rule='')
      case rule
      when String
        @string = rule
        @rule = Regexp.new(Regexp.escape(rule))
      when Regexp
        @rule = rule
      else
        raise ArgumentError, "Cannot create terminal from object: %s" % 
          rule.inspect
      end
    end

    # The actual Regexp object this rule uses to match.
    attr_reader :rule

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      m = input.scan(@rule)
      create_match(m) if m
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      (@string || @rule).inspect
    end
  end

  # A Nonterminal is a Rule that augments the matching behavior of one or more
  # other rules. Nonterminals may not match directly on the input, but instead
  # invoke the rule(s) they contain to determine if a match can be made from
  # the collective result.
  module Nonterminal
    include Rule

    def initialize(rules=[])
      @rules = rules.map {|r| Rule.new(r) }
    end

    # An array of the actual Rule objects this rule uses to match.
    attr_reader :rules

    def grammar=(grammar)
      @rules.each {|r| r.grammar = grammar }
      super
    end
  end

  # A Predicate is a Nonterminal that contains one other rule.
  module Predicate
    include Nonterminal

    def initialize(rule='')
      super([rule])
    end

    # Returns the Rule object this rule uses to match.
    def rule
      rules[0]
    end
  end

  # An AndPredicate is a Predicate that contains a rule that must match. Upon
  # success an empty match is returned and no input is consumed. The Citrus
  # notation is any expression preceded by an ampersand, e.g.:
  #
  #     &expr
  #
  class AndPredicate
    include Predicate

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      create_match('') if input.match(rule)
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      '&' + rule.embed
    end
  end

  # A NotPredicate is a Predicate that contains a rule that must not match. Upon
  # success an empty match is returned and no input is consumed. The Citrus
  # notation is any expression preceded by an exclamation mark, e.g.:
  #
  #     !expr
  #
  class NotPredicate
    include Predicate

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      create_match('') unless input.match(rule)
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      '!' + rule.embed
    end
  end

  # A ButPredicate is a Predicate that consumes all characters until its rule
  # matches. It must match at least one character in order to succeed. The
  # Citrus notation is any expression preceded by a tilde, e.g.:
  #
  #     ~expr
  #
  class ButPredicate
    include Predicate

    DOT_RULE = Rule.new(DOT)

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      matches = []
      while input.match(rule).nil?
        m = input.match(DOT_RULE)
        break unless m
        matches << m
      end
      # Create a single match from the aggregate text value of all submatches.
      create_match(matches.join) if matches.any?
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      '~' + rule.embed
    end
  end

  # A Label is a Predicate that applies a new name to any matches made by its
  # rule. The Citrus notation is any sequence of word characters (i.e.
  # <tt>[a-zA-Z0-9_]</tt>) followed by a colon, followed by any other
  # expression, e.g.:
  #
  #     label:expr
  #
  class Label
    include Predicate

    def initialize(rule='', label='<label>')
      super(rule)
      self.label = label
    end

    # Sets the name of this label.
    def label=(label)
      @label = label.to_sym
    end

    # The label this rule adds to all its matches.
    attr_reader :label

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    # When a Label makes a match, it re-names the match to the value of its
    # #label.
    def match(input)
      m = input.match(rule)
      extend_match(m, label) if m
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      label.to_s + ':' + rule.embed
    end
  end

  # A Repeat is a Predicate that specifies a minimum and maximum number of times
  # its rule must match. The Citrus notation is an integer, +N+, followed by an
  # asterisk, followed by another integer, +M+, all of which follow any other
  # expression, e.g.:
  #
  #     expr N*M
  #
  # In this notation +N+ specifies the minimum number of times the preceding
  # expression must match and +M+ specifies the maximum. If +N+ is ommitted,
  # it is assumed to be 0. Likewise, if +M+ is omitted, it is assumed to be
  # infinity (no maximum). Thus, an expression followed by only an asterisk may
  # match any number of times, including zero.
  #
  # The shorthand notation <tt>+</tt> and <tt>?</tt> may be used for the common
  # cases of <tt>1*</tt> and <tt>*1</tt> respectively, e.g.:
  #
  #     expr+
  #     expr?
  #
  class Repeat
    include Predicate

    def initialize(rule='', min=1, max=Infinity)
      super(rule)
      raise ArgumentError, "Min cannot be greater than max" if min > max
      @range = Range.new(min, max)
    end

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      matches = []
      while matches.length < @range.end
        m = input.match(rule)
        break unless m
        matches << m
      end
      create_match(matches) if @range.include?(matches.length)
    end

    # The minimum number of times this rule must match.
    def min
      @range.begin
    end

    # The maximum number of times this rule may match.
    def max
      @range.end
    end

    # Returns the operator this rule uses as a string. Will be one of
    # <tt>+</tt>, <tt>?</tt>, or <tt>N*M</tt>.
    def operator
      @operator ||= case [min, max]
        when [0, 0] then ''
        when [0, 1] then '?'
        when [1, Infinity] then '+'
        else
          [min, max].map {|n| n == 0 || n == Infinity ? '' : n.to_s }.join('*')
        end
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rule.embed + operator
    end
  end

  # A List is a Nonterminal that contains any number of other rules and tests
  # them for matches in sequential order.
  module List
    include Nonterminal

    # See Rule#paren?.
    def paren?
      rules.length > 1
    end
  end

  # A Choice is a List where only one rule must match. The Citrus notation is
  # two or more expressions separated by a vertical bar, e.g.:
  #
  #     expr | expr
  #
  class Choice
    include List

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      rules.each do |rule|
        m = input.match(rule)
        return extend_match(m, name) if m
      end
      nil
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rules.map {|r| r.embed }.join(' | ')
    end
  end

  # A Sequence is a List where all rules must match. The Citrus notation is two
  # or more expressions separated by a space, e.g.:
  #
  #     expr expr
  #
  class Sequence
    include List

    # Returns the Match for this rule on +input+, +nil+ if no match can be made.
    def match(input)
      matches = []
      rules.each do |rule|
        m = input.match(rule)
        break unless m
        matches << m
      end
      create_match(matches) if matches.length == rules.length
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rules.map {|r| r.embed }.join(' ')
    end
  end

  # The base class for all matches. Matches are organized into a tree where any
  # match may contain any number of other matches. This class provides several
  # convenient tree traversal methods that help when examining parse results.
  class Match < String
    def initialize(data)
      case data
      when String
        super(data)
      when Array
        super(data.join)
        @matches = data
      else
        raise ArgumentError, "Cannot create match from object: %s" % 
          data.inspect
      end
    end

    # An array of all names of this match. A name is added to a match object
    # for each rule that returns that object when matching. These names can then
    # be used to determine which rules were satisfied by a given match.
    def names
      @names ||= []
    end

    # The name of the lowest level rule that originally created this match.
    def name
      names.first
    end

    # Returns +true+ if this match has the given +name+.
    def has_name?(name)
      names.include?(name)
    end

    # An array of all sub-matches of this match.
    def matches
      @matches ||= []
    end

    # Returns an array of all sub-matches with the given +name+. If +deep+ is
    # +false+, returns only sub-matches that are immediate descendants of this
    # match.
    def find(name, deep=true)
      sym = name.to_sym
      ms = matches.select {|m| m.has_name?(sym) }
      matches.each {|m| ms.concat(m.find(name, deep)) } if deep
      ms
    end

    # A shortcut for retrieving the first immediate sub-match of this match. If
    # +name+ is given, attempts to retrieve the first immediate sub-match named
    # +name+.
    def first(name=nil)
      name.nil? ? matches.first : find(name, false).first
    end

    # Returns +true+ if this match has no descendants (was created from a
    # Terminal).
    def terminal?
      matches.length == 0
    end

    # Creates a new String object from the contents of this match.
    def to_s
      String.new(self)
    end

    # Allows sub-matches of this match to be retrieved by name as instance
    # methods.
    def method_missing(sym, *args)
      m = first(sym)
      return m if m
      raise 'No match named "%s" in %s (%s)' % [sym, self, name]
    end

    def to_ary
      # This method intentionally left blank to work around a bug in Ruby 1.9.
    end
  end
end

class Object
  # A sugar method for creating grammars.
  #
  #     grammar :Calc do
  #     end
  #
  #     module MyModule
  #       grammar :Calc do
  #       end
  #     end
  #
  def grammar(name, &block)
    obj = respond_to?(:const_set) ? self : Object
    obj.const_set(name, Citrus::Grammar.new(&block))
  rescue NameError
    raise ArgumentError, 'Invalid grammar name: %s' % name
  end
end
