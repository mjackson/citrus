module Citrus
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
end
