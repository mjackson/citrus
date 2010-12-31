module Citrus
  # A Nonterminal is a Rule that augments the matching behavior of one or more
  # other rules. Nonterminals may not match directly on the input, but instead
  # invoke the rule(s) they contain to determine if a match can be made from
  # the collective result.
  class Nonterminal < Rule
    def initialize(rules=[])
      super()
      @rules = rules.map {|r| Rule.for(r) }
    end

    # An array of the actual Rule objects this rule uses to match.
    attr_reader :rules

    def grammar=(grammar) # :nodoc:
      super
      @rules.each {|r| r.grammar = grammar }
    end
  end
end
