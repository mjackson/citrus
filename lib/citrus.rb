require 'strscan'

# Citrus is a compact and powerful parsing library for Ruby that combines the
# elegance and expressiveness of the language with the simplicity and power of
# parsing expressions.
#
# http://mjijackson.com/citrus
module Citrus
  autoload :File, 'citrus/file'

  VERSION = [2, 2, 2]

  # Returns the current version of Citrus as a string.
  def self.version
    VERSION.join('.')
  end

  # A pattern to match any character, including \\n.
  DOT = /./m

  Infinity = 1.0 / 0

  F = ::File

  CLOSE = -1

  # Loads the grammar from the given +file+ into the global scope using #eval.
  def self.load(file)
    file << '.citrus' unless F.file?(file)
    raise "Cannot find file #{file}" unless F.file?(file)
    raise "Cannot read file #{file}" unless F.readable?(file)
    eval(F.read(file))
  end

  # Evaluates the given Citrus parsing expression grammar +code+ in the global
  # scope. Returns an array of any grammar modules that are created. Implicitly
  # raises +SyntaxError+ on a failed parse.
  def self.eval(code)
    parse(code, :consume => true).value
  end

  # Parses the given Citrus +code+ using the given +options+. Returns the
  # generated match tree. Raises a +SyntaxError+ if the parse fails.
  def self.parse(code, options={})
    File.parse(code, options)
  end

  # A standard error class that all Citrus errors extend.
  class Error < RuntimeError; end

  # Raised when a match cannot be found.
  class NoMatchError < Error; end

  # Raised when a parse fails.
  class ParseError < Error
    # The +input+ given here is an instance of Citrus::Input.
    def initialize(input)
      @offset = input.max_offset
      @line_offset = input.line_offset(offset)
      @line_number = input.line_number(offset)
      @line = input.line(offset)
      super "Failed to parse input on line #{line_number} at offset #{line_offset}\n#{detail}"
    end

    # The 0-based offset at which the error occurred in the input, i.e. the
    # maximum offset in the input that was successfully parsed before the error
    # occurred.
    attr_reader :offset

    # The 0-based offset at which the error occurred on the line on which it
    # occurred in the input.
    attr_reader :line_offset

    # The 1-based number of the line in the input where the error occurred.
    attr_reader :line_number

    # The text of the line in the input where the error occurred.
    attr_reader :line

    # Returns a string that, when printed, gives a visual representation of
    # exactly where the error occurred on its line in the input.
    def detail
      "#{line}\n#{' ' * line_offset}^"
    end
  end

  # This class represents the core of the parsing algorithm. It wraps the input
  # string and serves matches to all nonterminals.
  class Input < StringScanner
    def initialize(string)
      super(string)
      @max_offset = 0
    end

    # The maximum offset in the input that was successfully parsed.
    attr_reader :max_offset

    # Resets all internal variables so that this object may be used in another
    # parse.
    def reset # :nodoc:
      @max_offset = 0
      super
    end

    # Returns the length of this input.
    def length
      string.length
    end

    # Returns an array containing the lines of text in the input.
    def lines
      string.send(string.respond_to?(:lines) ? :lines : :to_s).to_a
    end

    # Iterates over the lines of text in the input using the given +block+.
    def each_line(&block)
      string.each_line(&block)
    end

    # Returns the 0-based offset of the given +pos+ in the input on the line
    # on which it is found. +pos+ defaults to the current pointer position.
    def line_offset(pos=pos)
      p = 0
      each_line do |line|
        len = line.length
        return (pos - p) if p + len >= pos
        p += len
      end
      0
    end

    # Returns the 0-based number of the line that contains the character at the
    # given +pos+. +pos+ defaults to the current pointer position.
    def line_index(pos=pos)
      p = n = 0
      each_line do |line|
        p += line.length
        return n if p >= pos
        n += 1
      end
      0
    end

    # Returns the 1-based number of the line that contains the character at the
    # given +pos+. +pos+ defaults to the current pointer position.
    def line_number(pos=pos)
      line_index(pos) + 1
    end

    alias lineno line_number

    # Returns the text of the line that contains the character at the given
    # +pos+. +pos+ defaults to the current pointer position.
    def line(pos=pos)
      lines[line_index(pos)]
    end

    # Returns an array of events for the given +rule+ at the current pointer
    # position. Objects in this array may be one of three types: a rule id,
    # Citrus::CLOSE, or a length.
    def exec(rule, events=[])
      start = pos
      index = events.size

      rule.exec(self, events)

      if index < events.size
        self.pos = start + events[-1]
        @max_offset = pos if pos > @max_offset
      else
        self.pos = start
      end

      events
    end

    # Returns the length of a match for the given +rule+ at the current pointer
    # position, +nil+ if none can be made.
    def test(rule)
      rule.exec(self)[-1]
    end

    def memoized?
      false
    end
  end

  class MemoizingInput < Input
    # Modifies this object to cache match results during a parse. This technique
    # (also known as "Packrat" parsing) guarantees parsers will operate in
    # linear time but costs significantly more in terms of time and memory
    # required to perform a parse. For more information, please read the paper
    # on Packrat parsing at http://pdos.csail.mit.edu/~baford/packrat/icfp02/.
    def initialize(string)
      super string
      @cache = {}
      @cache_hits = 0
    end

    # A nested hash of rule id's to offsets and their respective matches. Only
    # present if memoing is enabled.
    attr_reader :cache

    # The number of times the cache was hit. Only present if memoing is enabled.
    attr_reader :cache_hits

    def exec(rule, events=[]) # :nodoc:
      c = @cache[rule.id] ||= {}

      e = if c[pos]
        @cache_hits += 1
        c[pos]
      else
        c[pos] = super(rule)
      end

      events.concat(e)
    end

    def reset # :nodoc:
      @cache.clear
      @cache_hits = 0
      super
    end

    # Returns +true+ when using memoization to cache match results.
    def memoized?
      true
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

    # Parses the given +string+ using this grammar's root rule. Optionally, the
    # name of a different rule may be given here as the value of the +:root+
    # option. Otherwise, all options are the same as in Rule#parse.
    def parse(string, options={})
      rule_name = options.delete(:root) || root
      rule = rule(rule_name)
      raise 'No rule named "%s"' % rule_name unless rule
      rule.parse(string, options)
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
      included_grammars.each do |grammar|
        rule = grammar.rule(sym)
        return rule if rule
      end
      nil
    end

    # Gets/sets the rule with the given +name+. If +obj+ is given the rule
    # will be set to the value of +obj+ passed through Rule.for. If a block is
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

        rule = Rule.for(obj)
        rule.name = name
        setup_super(rule, name)
        rule.grammar = self

        rules[sym] = rule
      end

      rules[sym] || super_rule(sym)
    rescue => e
      # This preserves the backtrace
      e.message.replace("Cannot create rule \"#{name}\": #{e.message}")
      raise e
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
      ext(Rule.for(DOT), block)
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
      rule = Rule.for(rule)
      mod = block if block
      rule.extension = mod if mod
      rule
    end
  end

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

    @unique_id = 0

    # A global registry for Rule objects. Keyed by rule id.
    @rules = {}

    # Adds the given +rule+ to the global registry and gives it an id.
    def self.<<(rule) # :nodoc:
      rule.id = (@unique_id += 1)
      @rules[rule.id] = rule
    end

    # Returns the Rule object with the given +id+.
    def self.[](id)
      @rules[id]
    end

    def initialize(*args) # :nodoc:
      Rule << self
    end

    # An integer id that is unique to this rule.
    attr_accessor :id

    # The grammar this rule belongs to.
    attr_accessor :grammar

    # Sets the name of this rule.
    def name=(name)
      @name = name.to_sym
    end

    # Returns the name of this rule.
    def name
      @name || '<anonymous>'
    end

    # Returns +true+ if this rule has a name, +false+ otherwise.
    def named?
      !!@name
    end

    # Specifies a module that will be used to extend all Match objects that
    # result from this rule. If +mod+ is a Proc, it is used to create an
    # anonymous module.
    def extension=(mod)
      if Proc === mod
        begin
          tmp = Module.new(&mod)
          raise ArgumentError if tmp.instance_methods.empty?
          mod = tmp
        rescue NoMethodError, ArgumentError, NameError
          mod = Module.new { define_method(:value, &mod) }
        end
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
    # rules to the scope of the parent, +false+ otherwise. In general, this will
    # return +false+ for any rule whose match value is derived from an arbitrary
    # number of child rules, such as a Repeat or a Sequence. Note that this is
    # not true for Choice objects because they rely on exactly 1 rule to match,
    # as do Proxy objects.
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
    def paren?
      false
    end

    # Returns a string version of this rule that is suitable to be used in the
    # string representation of another rule.
    def embed
      named? ? name.to_s : (paren? ? "(#{to_s})" : to_s)
    end

    def inspect # :nodoc:
      to_s
    end

    def extend_match(match) # :nodoc:
      match.names << name if named?
      match.extend(extension) if extension
    end
  end

  # A Terminal is a Rule that matches directly on the input stream and may not
  # contain any other rule. Terminals are essentially wrappers for regular
  # expressions. As such, the Citrus notation is identical to Ruby's regular
  # expression notation, e.g.:
  #
  #     /expr/
  #
  # Character classes and the dot symbol may also be used in Citrus notation for
  # compatibility with other parsing expression implementations, e.g.:
  #
  #     [a-zA-Z]
  #     .
  #
  class Terminal < Rule
    def initialize(rule=/^/)
      super
      @rule = rule
    end

    # The actual Regexp object this rule uses to match.
    attr_reader :rule

    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      length = input.scan_full(rule, false, false)
      if length
        events << id
        events << CLOSE
        events << length
      end
      events
    end

    # Returns +true+ if this rule is case sensitive.
    def case_sensitive?
      !rule.casefold?
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rule.inspect
    end
  end

  # A StringTerminal is a Terminal that may be instantiated from a String
  # object. The Citrus notation is any sequence of characters enclosed in either
  # single or double quotes, e.g.:
  #
  #     'expr'
  #     "expr"
  #
  # This notation works the same as it does in Ruby; i.e. strings in double
  # quotes may contain escape sequences while strings in single quotes may not.
  # In order to specify that a string should ignore case when matching, enclose
  # it in backticks instead of single or double quotes, e.g.:
  #
  #     `expr`
  #
  # Besides case sensitivity, case-insensitive strings have the same semantics
  # as double-quoted strings.
  class StringTerminal < Terminal
    # The +flags+ will be passed directly to Regexp#new.
    def initialize(rule='', flags=0)
      super(Regexp.new(Regexp.escape(rule), flags))
      @string = rule
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      if case_sensitive?
        @string.inspect
      else
        @string.inspect.gsub(/^"|"$/, '`')
      end
    end
  end

  # A Proxy is a Rule that is a placeholder for another rule. It stores the
  # name of some other rule in the grammar internally and resolves it to the
  # actual Rule object at runtime. This lazy evaluation permits us to create
  # Proxy objects for rules that we may not know the definition of yet.
  class Proxy < Rule
    def initialize(rule_name='<proxy>')
      super
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

    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << id

      index = events.size
      start = index - 1
      if input.exec(rule, events).size > index
        events << CLOSE
        events << events[-2]
      else
        events.slice!(start, events.size)
      end

      events
    end
  end

  # An Alias is a Proxy for a rule in the same grammar. It is used in rule
  # definitions when a rule calls some other rule by name. The Citrus notation
  # is simply the name of another rule without any other punctuation, e.g.:
  #
  #     name
  #
  class Alias < Proxy
    # Returns the Citrus notation of this rule as a string.
    def to_s
      rule_name.to_s
    end

  private

    # Searches this proxy's grammar and any included grammars for a rule with
    # this proxy's #rule_name. Raises an error if one cannot be found.
    def resolve!
      val = grammar.rule(rule_name)

      unless val
        raise RuntimeError,
          "No rule named \"#{rule_name}\" in grammar #{grammar.name}"
      end

      return val
    end
  end

  # A Super is a Proxy for a rule of the same name that was defined previously
  # in the grammar's inheritance chain. Thus, Super's work like Ruby's +super+,
  # only for rules in a grammar instead of methods in a module. The Citrus
  # notation is the word +super+ without any other punctuation, e.g.:
  #
  #     super
  #
  class Super < Proxy
    # Returns the Citrus notation of this rule as a string.
    def to_s
      'super'
    end

  private

    # Searches this proxy's included grammars for a rule with this proxy's
    # #rule_name. Raises an error if one cannot be found.
    def resolve!
      val = grammar.super_rule(rule_name)

      unless val
        raise RuntimeError,
          "No rule named \"#{rule_name}\" in hierarchy of grammar #{grammar.name}"
      end

      return val
    end
  end

  # A Nonterminal is a Rule that augments the matching behavior of one or more
  # other rules. Nonterminals may not match directly on the input, but instead
  # invoke the rule(s) they contain to determine if a match can be made from
  # the collective result.
  class Nonterminal < Rule
    def initialize(rules=[])
      super
      @rules = rules.map {|r| Rule.for(r) }
    end

    # An array of the actual Rule objects this rule uses to match.
    attr_reader :rules

    def grammar=(grammar) # :nodoc:
      super
      @rules.each {|r| r.grammar = grammar }
    end
  end

  # A Predicate is a Nonterminal that contains one other rule.
  class Predicate < Nonterminal
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
  class AndPredicate < Predicate
    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      if input.test(rule)
        events << id
        events << CLOSE
        events << 0
      end
      events
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
  class NotPredicate < Predicate
    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      unless input.test(rule)
        events << id
        events << CLOSE
        events << 0
      end
      events
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
  class ButPredicate < Predicate
    DOT_RULE = Rule.for(DOT)

    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      length = 0

      until input.test(rule)
        len = input.exec(DOT_RULE)[-1]
        break unless len
        length += len
      end

      if length > 0
        events << id
        events << CLOSE
        events << length
      end
      events
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
  class Label < Predicate
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

    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << id

      index = events.size
      start = index - 1

      if input.exec(rule, events).size > index
        events << CLOSE
        events << events[-2]
      else
        events.slice!(start, events.size)
      end

      events
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      label.to_s + ':' + rule.embed
    end

    def extend_match(match) # :nodoc:
      match.names << label
      super
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
  class Repeat < Predicate
    def initialize(rule='', min=1, max=Infinity)
      raise ArgumentError, "Min cannot be greater than max" if min > max
      super(rule)
      @range = Range.new(min, max)
    end

    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << id

      index = events.size
      start = index - 1
      length = n = 0

      while n < max && input.exec(rule, events).size > index
        index = events.size
        length += events[-1]
        n += 1
      end

      if n >= min
        events << CLOSE
        events << length
      else
        events.slice!(start, events.size)
      end

      events
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
  class List < Nonterminal
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
  class Choice < List
    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << id

      index = events.size
      start = index - 1
      n = 0

      while n < rules.length && input.exec(rules[n], events).size == index
        n += 1
      end

      if index < events.size
        events << CLOSE
        events << events[-2]
      else
        events.slice!(start, events.size)
      end

      events
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
  class Sequence < List
    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << id

      index = events.size
      start = index - 1
      length = n = 0

      while n < rules.length && input.exec(rules[n], events).size > index
        index = events.size
        length += events[-1]
        n += 1
      end

      if n == rules.length
        events << CLOSE
        events << length
      else
        events.slice!(start, events.size)
      end

      events
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rules.map { |r| r.embed }.join(' ')
    end
  end

  # The base class for all matches. Matches are organized into a tree where any
  # match may contain any number of other matches. This class provides several
  # convenient tree traversal methods that help when examining parse results.
  class Match
    def initialize(string, events=[])
      if events[-1] && string.length != events[-1]
        raise ArgumentError,
               "Invalid events for match length #{string.length}"
      end

      @string = string
      @events = events

      extend!
    end

    def to_s
      @string
    end

    alias_method :to_str, :to_s

    # The array of events that was passed to the constructor.
    attr_reader :events

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
      names.include?(name.to_sym)
    end

    # Returns an array of all Rule objects that extend this match.
    def extenders
      @extenders ||= begin
        extenders = []
        @events.each do |event|
          break if event == CLOSE
          rule = Rule[event]
          extenders.unshift(rule)
          break unless rule.propagates_extensions?
        end
        extenders
      end
    end

    # Returns an array of Match objects that are submatches of this match in the
    # order they appeared in the input.
    def matches
      @matches ||= begin
        matches = []
        stack = []
        offset = 0
        close = false
        index = 0

        while index < @events.size
          event = @events[index]
          if close
            start = stack.pop
            if stack.size == extenders.size
              matches << Match.new(slice(offset, event), @events[start..index])
              offset += event
            end
            close = false
          elsif event == CLOSE
            close = true
          else
            stack << index
          end
          index += 1
        end

        matches
      end
    end

    # Returns an array of all sub-matches with the given +name+. If +deep+ is
    # +false+, returns only sub-matches that are immediate descendants of this
    # match.
    def find(name, deep=true)
      ms = matches.select {|m| m.has_name?(name) }
      matches.each {|m| ms.concat(m.find(name, deep)) } if deep
      ms
    end

    # A shortcut for retrieving the first immediate sub-match of this match. If
    # +name+ is given, attempts to retrieve the first immediate sub-match named
    # +name+.
    def first(name=nil)
      name ? find(name, false).first : matches.first
    end

    # The default value for a match is its string value. This method is
    # overridden in most cases to be more meaningful according to the desired
    # interpretation.
    alias value to_s

    def ==(other)
      case other
      when String
        return @string == other
      when Match
        return @string == other.to_s
      else
        super
      end
    end

    # Allows sub-matches of this match to be retrieved by name as instance
    # methods.
    def method_missing(sym, *args)
      if @string.respond_to?(sym)
        @string.__send__ sym, *args
      else
        val = first(sym)

        unless val
          raise NoMatchError,
            "No match named \"#{sym}\" in #{self} (#{name})"
        end

        return val
      end
    end

    # Returns a string representation of this match that displays the entire
    # match tree for easy viewing in the console.
    def dump
      dump_lines.join("\n")
    end

    def dump_lines(indent='  ') # :nodoc:
      line = to_s.inspect
      line << " (" << names.join(',') << ")" unless names.empty?

      matches.inject([line]) do |lines, m|
        lines.concat(m.dump_lines(indent).map { |line| indent + line })
      end
    end

  private

    def extend! # :nodoc:
      extenders.each do |rule|
        rule.extend_match(self)
      end
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
    namespace = respond_to?(:const_set) ? self : Object
    namespace.const_set(name, Citrus::Grammar.new(&block))
  rescue NameError
    raise ArgumentError, 'Invalid grammar name: %s' % name
  end
end
