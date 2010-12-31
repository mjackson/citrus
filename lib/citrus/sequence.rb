module Citrus
  # A Sequence is a List where all rules must match. The Citrus notation is two
  # or more expressions separated by a space, e.g.:
  #
  #     expr expr
  #
  class Sequence < Nonterminal
    # Returns an array of events for this rule on the given +input+.
    def exec(input, events=[])
      events << self

      index = events.size
      start = index - 1
      length = n = 0

      while n < rules.length && input.exec(rules[n], events).size > index
        index = events.size
        length += events[-1]
        n += 1
      end

      if n == rules.length
        events << CLOSE
        events << length
      else
        events.slice!(start, events.size)
      end

      events
    end

    # Returns the Citrus notation of this rule as a string.
    def to_s
      rules.map {|r| r.embed }.join(' ')
    end
  end
end
