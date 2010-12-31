module Citrus
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
        events << self
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
end
