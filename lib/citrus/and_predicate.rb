module Citrus
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
        events << self
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
end
