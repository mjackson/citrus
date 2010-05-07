require 'forwardable'
require 'rexml/text'

# Citrus is a compact and powerful parsing library for Ruby that combines the
# elegance and expressiveness of the language with the simplicity and power of
# parsing expression grammars.
#
# http://mjijackson.com/citrus
module Citrus
  VERSION = [0, 1, 0]

  # The concept of infinity, which is most definitely not a number, which
  # distinction, in the grand scheme of things, most definitely does not matter.
  Infinity = 1.0 / 0

  # Returns the current version of Citrus as a string.
  def self.version
    VERSION.join('.')
  end

  # Loads the grammar from the given +file+ into the global scope using #eval!.
  def self.load(file)
    file << '.citrus' unless File.file?(file)
    raise "Cannot find file #{file}" unless File.file?(file)
    raise "Cannot read file #{file}" unless File.readable?(file)
    code = File.read(file)
    eval!(code)
  end

  # Evaluates the given Citrus grammar +code+ in the global scope.
  def self.eval!(code)
    require File.join(File.dirname(__FILE__), 'citrus', 'peg')
    file = PEG.parse!(code)
    file.eval!
  end

  # This error is raised whenever a parse fails.
  class ParseError < Exception
    extend Forwardable

    def initialize(input)
      @input = input
      c = consumed
      s = [0, c.length - 40].max
      msg  = "Failed to parse input at offset %d" % max_offset
      msg += ", just\n    after %s" % c[s, c.length].inspect + "\n"
      super(msg)
    end

    # The Input object that was used for the parse.
    attr_reader :input

    def_delegators :@input, :string, :length, :max_offset

    # Returns the portion of the input string that was successfully consumed
    # before the parse failed.
    def consumed
      input[0, max_offset]
    end
  end

  # May be extended by another Module in order to give it the ability to call
  # its own instance-level methods without using Module#module_function.
  module Invoke
    # Returns a blank instance of a Class that includes this module.
    def instance
      mod = self
      @instance ||= (Class.new { include mod }).new
    end

    # Invokes the instance-level method with the given name on a blank
    # #instance.
    def invoke(sym, *args)
      instance.__send__(sym, *args)
    end
  end

  # This module should be included in all grammars. Although it does not provide
  # any methods, constants, or variables to modules that include it, the mere
  # act of inclusion provides a useful lookup mechanism to determine if a module
  # is in fact a grammar.
  #
  # The instance-level of included modules is left untouched so that it provides
  # a clean slate for grammars to define their rules in.
  module Grammar
    # Creates a new Grammar as an anonymous module. If a block is provided, it
    # will be called with the new Grammar as its first argument if its +arity+
    # is 1 or +instance_eval+'d in the context of the new Grammar otherwise.
    # See http://blog.grayproductions.net/articles/dsl_block_styles for the
    # rationale behind this decision.
    #
    # Grammars created with this method may be assigned a name by being assigned
    # to some constant, e.g.:
    #
    #     Calc = Grammar.new {}
    #
    def self.new(&block)
      mod = Module.new { include Grammar }
      if block
        block.arity == 1 ? block[self] : mod.instance_eval(&block)
      end
      mod
    end

    # Extends all modules that +include Grammar+ with the GrammarDSL.
    def self.included(base)
      base.extend(GrammarDSL)
    end
  end

  # Contains methods that should be available to Grammar modules at the class
  # level.
  module GrammarDSL
    include Invoke

    # Functions just like Module#include except that we need to collect any
    # rule names from included grammars.
    def include(*args)
      super
      args.each do |mod|
        if mod.include?(Grammar)
          mod.rule_names.each do |name|
            rule_names << name unless has_rule?(name)
          end
        end
      end
    end

    # Returns the name of this grammar as a String.
    def name
      super.to_s
    end

    # Returns an array of all grammars that have been included in this grammar
    # in the reverse order they were included.
    def included_grammars
      included_modules.select {|mod| mod.include?(Grammar) }
    end

    # Returns an array of all names of rules in this grammar as symbols ordered
    # in the same way they were defined.
    def rule_names
      @rule_names ||= []
    end

    # Returns +true+ if this grammar contains a rule with the given +name+.
    def has_rule?(name)
      rule_names.include?(name.to_sym)
    end

    # Returns a hash of the names of all rules in this grammar to their
    # respective Rule objects.
    def rules
      rule_names.inject({}) {|m, sym| m[sym] = rule(sym); m }
    end

    # Parses the given +string+ from the given +offset+. A ParseError is raised
    # if there is no match made or if +consume_all+ is +true+ and the entire
    # input +string+ cannot be consumed.
    def parse!(string, offset=0, consume_all=true)
      raise "No root rule specified" unless root
      raise "No rule named \"#{root}\"" unless has_rule?(root)

      input = Input.new(string)
      match = input.match(rule(root), offset)

      if !match || (consume_all && match.length != string.length)
        raise ParseError.new(input)
      end

      match
    end

    # Gets/sets the Rule object with the given +name+. If a block is given,
    # will use the return value of the block as the object to pass to
    # Rule#create. All rules are stored as instance methods of the grammar
    # module so that grammars may be composed using Ruby's modules inclusion
    # mechanism.
    def rule(name, &block)
      sym = name.to_sym

      # Keep track of rule names that have been added to this grammar in the
      # order they are added.
      rule_names << sym unless has_rule?(sym)

      if block
        rule = Rule.create(block.call)
        raise "Rule may not be a Proxy object" if Proxy === rule
        rule.name = name
        rule.grammar = self
        define_method(sym) { rule }
      end

      invoke(sym) if has_rule?(name)
    rescue => e
      raise "Cannot create rule \"#{name}\": " + e.message
    end

    # Gets/sets the name of the root rule of this grammar.
    def root(name=nil)
      @root = name.to_sym if name
      # The first rule in a grammar is the default root.
      @root || rule_names.first
    end

    # Works like Ruby's +super+, but for rules. When defining a grammar, this
    # will return the Rule object from the most recently included grammar with
    # a rule of the same +name+. If +name+ is not supplied it defaults to the
    # name of the rule currently being defined.
    def sup(name=rule_names.last)
      included_grammars.each do |grammar|
        return grammar.rule(name) if grammar.has_rule?(name)
      end
      raise ArgumentError, "Cannot use super. No rule named \"#{name}\" " +
        "found in inheritance hierarchy"
    end

    # Specifies a Module that will be used to extend all matches created with
    # the given +rule+. A block may also be given that will be used to create
    # an anonymous module. See Rule#match_module=.
    def mod(rule, ext=nil)
      rule = Rule.create(rule)
      ext = Proc.new if block_given?
      rule.match_module = ext if ext
      rule
    end

    # Creates a new AndPredicate using the given +rule+. A block may be provided
    # to specify semantic behavior (via #mod).
    def andp(rule, &block)
      mod(AndPredicate.new(rule), block)
    end

    # Creates a new NotPredicate using the given +rule+. A block may be provided
    # to specify semantic behavior (via #mod).
    def notp(rule, &block)
      mod(NotPredicate.new(rule), block)
    end

    # Creates a new Label using the given +rule+ and +label+.
    def label(rule, label, &block)
      mod(Label.new(label, rule), block)
    end

    # Creates a new Repeat using the given +rule+. +min+ and +max+ specify the
    # minimum and maximum number of times the rule must match. A block may be
    # provided to specify semantic behavior (via #mod).
    def rep(rule, min=1, max=Infinity, &block)
      mod(Repeat.new(min, max, rule), block)
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
    # specify semantic behavior (via #mod).
    def all(*args, &block)
      mod(Sequence.new(args), block)
    end

    # Creates a new Choice using all arguments. A block may be provided to
    # specify semantic behavior (via #mod).
    def any(*args, &block)
      mod(Choice.new(args), block)
    end
  end

  # The core of the packrat parsing algorithm, this class wraps a string that
  # is to be parsed and keeps a cache of matches for all rules at any given
  # offset. See http://pdos.csail.mit.edu/~baford/packrat/icfp02/ for more
  # information on packrat parsing.
  class Input
    extend Forwardable

    def initialize(string)
      @string = string
      @cache = {}
      @cache_hits = 0
      @max_offset = 0
    end

    def_delegators :@string, :[], :length

    # The input string.
    attr_reader :string

    # A two-level hash of rule id's and offsets to their respective matches.
    attr_reader :cache

    # The number of times the cache was hit.
    attr_reader :cache_hits

    # The maximum offset that has been achieved.
    attr_reader :max_offset

    # Returns the match for a given +rule+ at a given +offset+. If no such match
    # exists in the cache, the rule is executed and the result is cached before
    # returning.
    def match(rule, offset=0)
      c = @cache[rule.id] ||= {}

      @max_offset = offset if offset > @max_offset

      if c.key?(offset)
        @cache_hits += 1
        c[offset]
      else
        c[offset] = rule.match(self, offset)
      end
    end
  end

  # A Rule is an object that is used during parsing to match on the Input. This
  # class serves as an abstract base for all other rule classes and should
  # not be directly instantiated.
  class Rule
    # Returns a new Rule object depending on the type of object given.
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
        raise ArgumentError, "Invalid rule object: #{obj.inspect}"
      end
    end

    # The grammar this rule belongs to.
    attr_accessor :grammar

    # Returns a String id that is unique to this Rule object.
    def id
      object_id.to_s
    end

    # Sets the name of this rule.
    def name=(name)
      @name = name.to_sym
    end

    # The name of this rule.
    attr_reader :name

    # Specifies a module that will be used to extend all Match objects that
    # result from this rule. If +mod+ is a Proc, it will be used to create an
    # anonymous module.
    def match_module=(mod)
      mod = Module.new(&mod) if Proc === mod
      @match_module = mod
    end

    # The module this rule uses to extend new matches.
    attr_reader :match_module

    # Returns +true+ if this rule is a Terminal.
    def terminal?
      is_a?(Terminal)
    end

    # Returns +true+ if this rule needs to be surrounded by parentheses when
    # using #embed.
    def paren?
      false
    end

    # Returns a string version of this rule that is suitable to be used as part
    # of the string representation of some other rule.
    def embed
      name ? name.to_s : (paren? ? '(%s)' % to_s : to_s)
    end

    def inspect # :nodoc:
      to_s
    end

  private

    def create_match(result)
      result = [result] if Match === result
      match = Match.new(result)
      match.extend(match_module) if match_module
      match.name = name
      match
    end
  end

  # A Proxy is a Rule that is a placeholder for another rule. It is used in
  # grammar definitions when a rule calls some other rule by name. The PEG
  # notation is simply the name of a rule without any other punctuation, e.g.:
  #
  #     name
  #
  class Proxy < Rule
    def initialize(name='')
      @rule_name = name.to_sym
    end

    # The name of the rule this rule is proxy for.
    attr_reader :rule_name

    # Returns the underlying Rule object for this Proxy. Lazily evaluated so
    # we can create Proxy objects before we know what the actual rule looks
    # like.
    def rule
      @rule = grammar.rule(rule_name)
      raise RuntimeError, "No rule named \"#{rule_name}\" in grammar " +
        grammar.name unless @rule
      # Dynamically redefine #rule for a small speed-up on future calls.
      instance_eval('def rule; @rule end')
      @rule
    end

    # Raises an error if the user tries to set a module for matches from this
    # proxy. The reason for this is that proxy objects do not create matches
    # like all other rules do. Instead, they simply pass the call to #match
    # along to #rule and return the result. This is to make them as transparent
    # as possible in the resulting match tree.
    def match_module=(*args)
      raise "Proxy objects may not modify a match"
    end

    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
    def match(input, offset=0)
      input.match(rule, offset)
    end

    # Returns the PEG notation of this rule as a string.
    def to_s
      rule_name.to_s
    end
  end

  # A Terminal is a Rule that matches directly on the input stream and may not
  # contain any other rule.
  class Terminal < Rule
    def initialize(rule)
      @rule = rule
    end

    # The actual String or Regexp object this rule uses to match.
    attr_reader :rule

    # Returns the PEG notation of this rule as a string.
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

    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
    def match(input, offset=0)
      create_match(rule.dup) if rule == input[offset, rule.length]
    end
  end

  # An Expression is a Terminal that has the same semantics as a regular
  # expression in Ruby. The expression must match at the beginning of the input
  # (index 0). The PEG notation is identical to Ruby's regular expression
  # notation, e.g.:
  #
  #     /expr/
  #
  # Character classes and the dot symbol may also be used in PEG notation for
  # compatibility with other PEG implementations, e.g.:
  #
  #     [a-zA-Z]
  #     .
  #
  class Expression < Terminal
    def initialize(rule=/^/)
      raise ArgumentError, "Expression must be a Regexp" unless Regexp === rule
      super
    end

    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
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
    def initialize(rules=[])
      @rules = rules.map {|r| Rule.create(r) }
    end

    # An array of the actual Rule objects this rule uses to match.
    attr_reader :rules

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

    # Returns the Rule object this rule uses to match.
    def rule
      rules[0]
    end
  end

  # An AndPredicate is a Predicate that contains a rule that must match. Upon
  # success an empty match is returned and no input is consumed. The PEG
  # notation is any expression preceeded by an ampersand, e.g.:
  #
  #     &expr
  #
  class AndPredicate < Predicate
    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
    def match(input, offset=0)
      create_match('') if input.match(rule, offset)
    end

    # Returns the PEG notation of this rule as a string.
    def to_s
      '&' + rule.embed
    end
  end

  # A NotPredicate is a Predicate that contains a rule that must not match. Upon
  # success an empty match is returned and no input is consumed. The PEG
  # notation is any expression preceeded by an exclamation mark, e.g.:
  #
  #     !expr
  #
  class NotPredicate < Predicate
    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
    def match(input, offset=0)
      create_match('') unless input.match(rule, offset)
    end

    # Returns the PEG notation of this rule as a string.
    def to_s
      '!' + rule.embed
    end
  end

  # A Label is a Predicate that applies a new name to any matches made by its
  # rule. The PEG notation is any sequence of word characters (i.e.
  # <tt>[a-zA-Z0-9_]</tt>) followed by a colon, followed by any other
  # expression, e.g.:
  #
  #     label:expr
  #
  class Label < Predicate
    def initialize(label='', rule='')
      @label = label.to_s
      super(rule)
    end

    # The string this rule uses to re-name all its matches.
    attr_reader :label

    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made. When a Label makes a match, it re-names the match to
    # the value of its label.
    def match(input, offset=0)
      m = rule.match(input, offset)
      if m
        m = create_match(m)
        m.name = label
        m
      end
    end

    # Returns the PEG notation of this rule as a string.
    def to_s
      label + ':' + rule.embed
    end
  end

  # A Repeat is a Predicate that specifies a minimum and maximum number of times
  # its rule must match. The PEG notation is an integer, +N+, followed by an
  # asterisk, followed by another integer, +M+, all of which follow any other
  # expression, e.g.:
  #
  #     expr N*M
  #
  # In this notation +N+ specifies the minimum number of times the preceeding
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
    def initialize(min=1, max=Infinity, rule='')
      raise ArgumentError, "Min cannot be greater than max" if min > max
      @range = Range.new(min, max)
      super(rule)
    end

    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
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

    # Returns the operator this rule uses as a string. Will be one of
    # <tt>+</tt>, <tt>?</tt>, or <tt>N*M</tt>.
    def operator
      unless @operator
        m = [@range.begin, @range.end].map do |n|
          n == 0 || n == Infinity ? '' : n.to_s
        end
        @operator = case m
          when ['', '1'] then '?'
          when ['1', ''] then '+'
          else m.join('*')
          end
      end
      @operator
    end

    # Returns the PEG notation of this rule as a string.
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
  # or more expressions separated by a vertical bar, e.g.:
  #
  #     expr | expr
  #
  class Choice < List
    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
    def match(input, offset=0)
      rules.each do |rule|
        m = input.match(rule, offset)
        return create_match(m) if m
      end
      nil
    end

    # Returns the PEG notation of this rule as a string.
    def to_s
      rules.map {|r| r.embed }.join(' | ')
    end
  end

  # A Sequence is a List where all rules must match. The PEG notation is two or
  # more expressions separated by a space, e.g.:
  #
  #     expr expr
  #
  class Sequence < List
    # Returns the Match for this rule on +input+ at the given +offset+, +nil+ if
    # no match can be made.
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

    # Returns the PEG notation of this rule as a string.
    def to_s
      rules.map {|r| r.embed }.join(' ')
    end
  end

  # The base class for all matches. Matches are organized into a parse tree
  # where any match may contain any number of other matches. This class provides
  # several convenient tree traversal methods that help when examining parse
  # results.
  class Match
    def initialize(result=nil)
      @matches = []
      @captures = []

      case result
      when String
        @text = result
      when MatchData
        @text = result[0]
        @captures = result.captures
      when Array
        @matches = result
      else
        raise ArgumentError, "Invalid match result: #{result.inspect}"
      end
    end

    # An array of all sub-matches of this match.
    attr_reader :matches

    # An array of substrings returned by MatchData#captures if this match was
    # created by an Expression.
    attr_reader :captures

    # The name by which this match can be accessed from a parent match. This
    # will be the name of the rule that generated the match in most cases.
    # However, if the match is the result of a Label this will be the value of
    # the label.
    attr_accessor :name

    # Returns the raw text value of this match, which may simply be an
    # aggregate of the text of all sub-matches if this match is not #terminal?.
    def text
      @text ||= matches.inject('') {|s, m| s << m.text }
    end

    alias to_s text

    # Returns the length of this match's #text value as an Integer.
    def length
      text.length
    end

    # Passes all arguments to the #text of this match.
    def [](*args)
      text.__send__(:[], *args)
    end

    # Returns an array of all sub-matches with the given +name+. If +deep+ is
    # +false+, returns only sub-matches that are immediate descendants of this
    # match.
    def find(name, deep=true)
      sym = name.to_sym
      ms = matches.select {|m| sym == m.name }
      ms.concat(matches.map {|m| m.find(name, deep) }.flatten) if deep
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

    # Checks equality by comparing this match's #text value to +obj+.
    def ==(obj)
      text == obj
    end

    alias eql? ==

    # Uses #match to allow sub-matches of this match to be called by name as
    # instance methods.
    def method_missing(sym, *args)
      m = first(sym)
      return m if m
      raise "No match named \"#{sym}\" in #{self}"
    end

    # Returns the result of #to_markup as a String (unless an alternate target
    # was specified).
    def to_xml(indent='  ', level=0)
      margin = indent * level
      eol = indent == '' ? '' : "\n"
      xml = level == 0 ? "<?xml version=\"1.0\"?>\n" : ''

      attrs = %w< name text >.map {|attr|
        "#{attr}=\"%s\"" % XChar.escape(__send__(attr.to_sym).to_s)
      }.join(' ')

      xml << margin + "<match #{attrs}"

      if matches.empty?
        xml << "/>"
      else
        xml << ">" + eol
        matches.each {|m| xml << m.to_xml(indent, level + 1) + eol }
        xml << margin + "</match>"
      end
    end

    def inspect # :nodoc:
      to_xml
    end
  end

  # XML Character converter, from Sam Ruby.
  # http://intertwingly.net/stories/2005/09/28/xchar.rb
  module XChar # :nodoc:
    # http://intertwingly.net/stories/2004/04/14/i18n.html#CleaningWindows
    CP1252 = { # :nodoc:
      128 => 8364,  # euro sign
      130 => 8218,  # single low-9 quotation mark
      131 =>  402,  # latin small letter f with hook
      132 => 8222,  # double low-9 quotation mark
      133 => 8230,  # horizontal ellipsis
      134 => 8224,  # dagger
      135 => 8225,  # double dagger
      136 =>  710,  # modifier letter circumflex accent
      137 => 8240,  # per mille sign
      138 =>  352,  # latin capital letter s with caron
      139 => 8249,  # single left-pointing angle quotation mark
      140 =>  338,  # latin capital ligature oe
      142 =>  381,  # latin capital letter z with caron
      145 => 8216,  # left single quotation mark
      146 => 8217,  # right single quotation mark
      147 => 8220,  # left double quotation mark
      148 => 8221,  # right double quotation mark
      149 => 8226,  # bullet
      150 => 8211,  # en dash
      151 => 8212,  # em dash
      152 =>  732,  # small tilde
      153 => 8482,  # trade mark sign
      154 =>  353,  # latin small letter s with caron
      155 => 8250,  # single right-pointing angle quotation mark
      156 =>  339,  # latin small ligature oe
      158 =>  382,  # latin small letter z with caron
      159 =>  376,  # latin capital letter y with diaeresis
    }

    # http://www.w3.org/TR/REC-xml/#dt-chardata
    PREDEFINED = {
      38 => '&amp;',  # ampersand
      60 => '&lt;',   # left angle bracket
      62 => '&gt;',   # right angle bracket
    }

    # http://www.w3.org/TR/REC-xml/#charsets
    VALID = [
      0x9, 0xA, 0xD,
      (0x20..0xD7FF),
      (0xE000..0xFFFD),
      (0x10000..0x10FFFF)
    ]

    # XML escaped version of Fixnum#chr for +n+. When +esc+ is set to false the
    # CP1252 fix is still applied but utf-8 characters are not converted to
    # character entities.
    def self.xchr(n, esc=true)
      n = XChar::CP1252[n] || n
      case n when *XChar::VALID
        XChar::PREDEFINED[n] or (n < 128 ? n.chr : (esc ? "&##{n};" : [n].pack('U*')))
      else
        '*'
      end
    end

    # XML escaped version of String#to_s for +s+. When +esc+ is set to false the
    # CP1252 fix is still applied but utf-8 characters are not converted to
    # character entities.
    def self.escape(s, esc=true)
      s.unpack('U*').map {|n| xchr(n, esc) }.join # ASCII, UTF-8
    rescue
      s.unpack('C*').map {|n| xchr(n) }.join # ISO-8859-1, WIN-1252
    end
  end
end
