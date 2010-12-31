module Citrus
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
      events << self

      index = events.size
      start = index - 1
      length = n = 0

      while n < max && input.exec(rule, events).size > index
        index = events.size
        length += events[-1]
        n += 1
      end

      # If enough rules match, register the repeat as matched
      # by closing it.
      if n >= min
        events << CLOSE
        events << length
      else
        # Otherwise remove the repeat entry from the event stream
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
end
