module Citrus
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
        events << self
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
end
