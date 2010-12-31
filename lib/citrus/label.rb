module Citrus
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
      events << self

      prev_size = events.size
      start = prev_size - 1

      # If the associated rule matches (adds events)
      # then close the label and set it's stream position
      # to be the position of the matched expression.
      if input.exec(rule, events).size > prev_size
        events << CLOSE
        events << events[-2]
      else
        # Remove the label rule since the associated expression
        # didn't match.
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
end
