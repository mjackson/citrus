module Citrus
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

    # Make the extension to rule be a module which is extended to the Match
    # object
    def mod(rule, &block)
      rule.extension = Module.new(&block)
      rule
    end
  end
end
