module Citrus
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
      super()
      @rule = rule
    end

    # The actual Regexp object this rule uses to match.
    attr_reader :rule

    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      length = input.scan_full(rule, false, false)
      if length
        events << self
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
end
